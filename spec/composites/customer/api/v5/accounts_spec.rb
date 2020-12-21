# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/repositories/account_repository"
require "composites/customer/constituents/account/interactors/verify_reset_password_token"

describe Customer::Api::V5::Accounts, :integration, type: :request do
  before do
    allow(Settings).to receive_message_chain(:app_features, :clark2) { true }
  end

  describe "POST /api/customer/current/account" do
    let(:customer) { create(:customer, :prospect) }
    let(:params) { {email: "example@gmail.com", password: "Test1234"} }

    it "creates a new account for customer" do
      login_customer(customer, scope: :lead)

      json_post_v5 "/api/customer/current/account", params
      expect(response.status).to eq 201

      repo = Customer::Constituents::Account::Repositories::AccountRepository.new
      account = repo.find_by(customer_id: customer.id)
      expect(account).to be_present
      expect(account.state).to eq "active"

      json_post_v5 "/api/customer/current/account", params
      expect(response.status).to eq 200
    end

    it "notifies customer" do
      # Needed to create an interaction
      create(:admin)

      login_customer(customer, scope: :lead)

      perform_enqueued_jobs do
        json_post_v5 "/api/customer/current/account", params
        expect(response.status).to eq 201
        mandate = Mandate.find(customer.id)
        expect(mandate.interactions).not_to be_empty
        expect(mandate.interactions.last.content).to eq I18n.t("messenger.self_service_customer_created.content")
      end
    end

    context "when data is invalid" do
      let(:account) { create(:account) }
      let(:email)    { account.email }
      let(:password) { "Test1234" }
      let(:params)   { { email: email, password: password } }

      before do
        login_customer(customer, scope: :lead)
      end

      it "returns an validation error" do
        # when email is taken
        json_post_v5 "/api/customer/current/account", params
        expect(response.status).to eq 422
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
        expect(json_response.errors.first["meta"]["data"]["email"]).not_to be_empty

        # when some parameters are missing
        json_post_v5 "/api/customer/current/account", email: email
        expect(response.status).to eq 422
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
        expect(json_response.errors.first["meta"]["data"]["password"]).not_to be_empty

        # when email is invalid
        json_post_v5 "/api/customer/current/account", email: "test", password: password
        expect(response.status).to eq 422
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
        expect(json_response.errors.first["meta"]["data"]["email"]).not_to be_empty

        # when password is invalid
        json_post_v5 "/api/customer/current/account", email: email, password: "qwerty"
        expect(response.status).to eq 422
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
        expect(json_response.errors.first["meta"]["data"]["password"]).not_to be_empty
      end
    end

    context "when customer is not authorized" do
      it "returns an error" do
        json_post_v5 "/api/customer/current/account", params
        expect(response.status).to eq 401
      end
    end
  end

  describe "POST /api/customer/.account/reset-password/verify" do
    let(:customer) { create(:customer, :self_service) }

    before { Timecop.freeze(Time.now) }

    after { Timecop.return }

    it "verifies the token" do
      # returns 400 without reset_password_token param
      json_post_v5 "/api/customer/.account/reset-password/verify"
      expect(response.status).to eq 400

      # returns 422 with invalid reset_password_token param
      # error response will contain meta object with result attribute
      json_post_v5 "/api/customer/.account/reset-password/verify", reset_password_token: "invalid"
      expect(response.status).to eq 422
      expect(json_response["errors"].first["meta"]["result"]).to eq("invalid")

      # returns 200 with valid reset_password_token
      user = User.find_by(mandate_id: customer.id)
      token = user&.send(:set_reset_password_token)
      json_post_v5 "/api/customer/.account/reset-password/verify", reset_password_token: token
      expect(response.status).to eq 200

      # returns 422 with expired reset_password_token
      # error response will contain meta object with result and email attributes
      expiration_time = Customer::Constituents::Account::Interactors::VerifyResetPasswordToken::EXPIRATION_TIME
      Timecop.freeze(Time.now + expiration_time + 1.second) do
        json_post_v5 "/api/customer/.account/reset-password/verify", reset_password_token: token
        expect(response.status).to eq 422
        expect(json_response["errors"].first["meta"]["result"]).to eq("expired")
        expect(json_response["errors"].first["meta"]["email"]).to eq(user.email)
      end
    end
  end

  describe "POST /api/customer/.account/reset-password/request" do
    let(:request) do
      json_post_v5 "/api/customer/.account/reset-password/request", params
    end

    context "with a valid e-mail" do
      let(:user) { create(:user, :with_mandate) }
      let(:params) { { email: user.email } }

      it "generates a reset password token and send it to the customer" do
        perform_enqueued_jobs do
          expect { request }.to change(ActionMailer::Base.deliveries, :count).by(1)
          expect(response).to have_http_status(:ok)

          user.reload
          expect(user.reset_password_token).not_to be_nil
          expect(user.reset_password_sent_at).not_to be_nil
        end
      end
    end

    context "with an invalid e-mail" do
      let(:params) { { email: "invalid-email@sample" } }

      it "ignores the request" do
        perform_enqueued_jobs do
          expect { request }.not_to change(ActionMailer::Base.deliveries, :count)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "without e-mail on request" do
      let(:params) { {} }

      it "returns a bad_request error" do
        perform_enqueued_jobs do
          expect { request }.not_to change(ActionMailer::Base.deliveries, :count)
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end

  describe "POST /api/customer/.account/reset-password/change" do
    let(:customer) { create(:customer, :self_service) }
    let(:user) { User.find_by(mandate_id: customer.id) }
    let(:token) { user.send(:set_reset_password_token) }
    let(:password) { "Test12345" }

    it "updates the password, sign-in customer and clears reset password token" do
      params = { password: password, reset_password_token: token }
      json_post_v5 "/api/customer/.account/reset-password/change", params

      expect(response.status).to eq 200
      expect(request.env["warden"].user(:user).id).to eq(user.id)
      expect(User.with_reset_password_token(token)).to eq(nil)
      expect(user.reload.valid_password?(params[:password])).to eq(true)
    end

    it "returns validation errors" do
      # returns 400 without required param
      json_post_v5 "/api/customer/.account/reset-password/change"
      expect(response.status).to eq 400

      # returns 401 with invalid password_reset_token param
      params = { password: "Test12345", reset_password_token: "invalid" }
      json_post_v5 "/api/customer/.account/reset-password/change", params
      expect(response.status).to eq 401

      # returns 422 with invalid password but valid password_reset_token params
      params = { password: "invalid", reset_password_token: token }
      json_post_v5 "/api/customer/.account/reset-password/change", params
      expect(response.status).to eq 422
    end
  end
end
