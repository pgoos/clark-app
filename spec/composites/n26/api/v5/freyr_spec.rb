# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/repositories/customer_repository"
require "composites/n26/constituents/freyr/entities/customer"

describe N26::Api::V5::Freyr, :integration, type: :request do
  let(:email) { "n26@email.com" }

  let(:mandate) {
    create(
      :mandate,
      :owned_by_n26
    )
  }

  describe "PUT /api/n26/freyr/customer/start_migration" do
    context "when a valid N26 customer exists with the email" do
      let(:valid_params) { { email: email } }

      let!(:user) {
        create(
          :user,
          email: email,
          mandate: mandate
        )
      }

      it "returns 200 code and customer entity" do
        json_put_v5("/api/n26/freyr/customer/start_migration", valid_params)
        customer = N26::Constituents::Freyr::Repositories::CustomerRepository
                   .new
                   .find_by_email(email)

        expect(response.status).to eq 200
        expect(json_response["data"]["id"]).to eq(customer.id)
      end
    end

    context "when no customer exists with the email" do
      it "returns 404 code" do
        json_put_v5("/api/n26/freyr/customer/start_migration", { email: "fake@fake.com" })
        expect(response.status).to eq 404
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when a customer exists with the email but not N26" do
      let(:non_n26_email) { "not_n26@test.com" }

      let!(:non_n26_user) {
        create(
          :user,
          email: non_n26_email,
          mandate: create(:mandate)
        )
      }

      it "returns 400 code" do
        json_put_v5("/api/n26/freyr/customer/start_migration", { email: non_n26_email })
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when an N26 customer exists but has previously been migrated" do
      let(:migrated_n26_email) { "migrated_n26@test.com" }

      let(:migrated_n26_mandate) {
        create(
          :mandate,
          info: {
            freyr: {
              migration_state: N26::Constituents::Freyr::Entities::Customer::State::MIGRATED
            }
          }
        )
      }

      let!(:migrated_n26_user) {
        create(
          :user,
          email: migrated_n26_email,
          mandate: migrated_n26_mandate
        )
      }

      it "returns 400 code" do
        json_put_v5("/api/n26/freyr/customer/start_migration", { email: migrated_n26_email })
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end
  end

  describe "PATCH /api/n26/freyr/customer/verify_phone" do
    let(:migration_token) { SecureRandom.alphanumeric(16) }
    let(:verification_token) { SecureRandom.random_number((1_000...10_000)).to_s }
    let(:phone_number) { "491771661232" }
    let(:params) { { migration_token: migration_token, verification_code: verification_token } }
    let(:mandate) {
      create(
        :mandate,
        :freyr_with_data,
        migration_token: migration_token,
        migration_state: N26::Constituents::Freyr::Entities::Customer::State::PHONE_ADDED
      )
    }

    before do
      # Saving phone number and generating verification code
      Platform::PhoneVerification.new(mandate, verification_token).create_sms_verification(phone_number)
    end

    it "returns 200 code with customer data" do
      json_patch_v5("/api/n26/freyr/customer/verify_phone", params)
      expect(response.status).to eq 200
      expect(json_response["data"]["id"]).to eq(mandate.id)
    end

    context "when no customer exists with the token" do
      let(:params) { { migration_token: "1122", verification_code: verification_token } }

      it "returns 404 code" do
        json_patch_v5("/api/n26/freyr/customer/verify_phone", params)
        expect(response.status).to eq 404
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when customer is not in eligible migration state to verify phone" do
      let(:mandate) {
        create(
          :mandate,
          :freyr_with_data,
          migration_token: migration_token,
          migration_state: N26::Constituents::Freyr::Entities::Customer::State::EMAIL_VERIFIED
        )
      }

      it "returns 400 code" do
        json_patch_v5("/api/n26/freyr/customer/verify_phone", params)
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when verification token is not valid" do
      let(:params) { { migration_token: migration_token, verification_code: "11" } }

      it "returns 400 code" do
        json_patch_v5("/api/n26/freyr/customer/verify_phone", params)
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end
  end

  describe "POST /api/n26/freyr/customer/save_phone_number" do
    let(:phone_number) { "491771661232" }
    let(:migration_token) { SecureRandom.alphanumeric(16) }
    let(:params) { { migration_token: migration_token, phone_number: phone_number } }

    context "when no customer exists with the token" do
      let(:params) { { migration_token: "1122", phone_number: phone_number } }

      it "returns 404 code" do
        json_post_v5("/api/n26/freyr/customer/save_phone_number", params)
        expect(response.status).to eq 404
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when customer is not in eligible migration state to save phone" do
      let!(:mandate) {
        create(
          :mandate,
          :owned_by_n26,
          info: { freyr: { migration_token: migration_token, migration_state: "" } }
        )
      }

      it "returns 400 code" do
        json_post_v5("/api/n26/freyr/customer/save_phone_number", params)
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when phone_number is not valid" do
      let!(:mandate) {
        create(
          :mandate,
          :owned_by_n26,
          info: { freyr: { migration_token: migration_token, migration_state: "" } }
        )
      }

      let(:params) { { migration_token: migration_token, phone_number: "1223" } }

      it "returns 400 code" do
        json_post_v5("/api/n26/freyr/customer/save_phone_number", params)
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when there is a customer which has already added phone number" do
      let!(:mandate) {
        create(
          :mandate,
          :owned_by_n26,
          :freyr_with_data,
          migration_token: migration_token,
          migration_state: N26::Constituents::Freyr::Entities::Customer::State::PHONE_ADDED,
          phone: "+491771661232"
        )
      }

      it "returns 201 code with customer data" do
        json_post_v5("/api/n26/freyr/customer/save_phone_number", migration_token: migration_token)
        expect(response.status).to eq 201
        expect(json_response["data"]["id"]).to eq(mandate.id)
      end
    end

    context "when there is an eligible customer with valid phone_number" do
      let!(:mandate) {
        create(
          :mandate,
          :owned_by_n26,
          info: {
            freyr: {
              migration_token: migration_token,
              migration_state: N26::Constituents::Freyr::Entities::Customer::State::EMAIL_VERIFIED
            }
          }
        )
      }

      it "returns 201 code with customer data" do
        json_post_v5("/api/n26/freyr/customer/save_phone_number", params)
        expect(response.status).to eq 201
        expect(json_response["data"]["id"]).to eq(mandate.id)
      end
    end
  end

  describe "PATCH /api/n26/freyr/customer/reset_password" do
    let(:migration_token) { SecureRandom.alphanumeric(16) }
    let(:password) { "Test123456" }
    let(:params) { { migration_token: migration_token, password: password } }
    let!(:mandate) {
      create(
        :mandate,
        :with_user,
        :freyr_with_data,
        migration_token: migration_token,
        migration_state: N26::Constituents::Freyr::Entities::Customer::State::PHONE_VERIFIED
      )
    }

    it "returns 200 code with customer data" do
      json_patch_v5("/api/n26/freyr/customer/reset_password", params)

      expect(response.status).to eq 200
      expect(json_response["data"]["id"]).to eq(mandate.id)
    end

    context "when no customer exists with the token" do
      let(:params) { { migration_token: "1122", password: password } }

      it "returns 404 code" do
        json_patch_v5("/api/n26/freyr/customer/reset_password", params)
        expect(response.status).to eq 404
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when customer is not in eligible migration state to verify phone" do
      let!(:mandate) {
        create(
          :mandate,
          :with_user,
          :freyr_with_data,
          migration_token: migration_token,
          migration_state: N26::Constituents::Freyr::Entities::Customer::State::EMAIL_VERIFIED
        )
      }

      it "returns 400 code" do
        json_patch_v5("/api/n26/freyr/customer/reset_password", params)
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when customer is not owned by n26" do
      let!(:mandate) {
        create(
          :mandate,
          :with_user,
          :freyr_with_data,
          owner_ident: "clark",
          migration_token: migration_token,
          migration_state: N26::Constituents::Freyr::Entities::Customer::State::PHONE_VERIFIED
        )
      }

      it "returns 400 code" do
        json_patch_v5("/api/n26/freyr/customer/reset_password", params)
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when password complexity is not valid" do
      let(:params) { { migration_token: migration_token, password: "11" } }

      it "returns 400 code" do
        json_patch_v5("/api/n26/freyr/customer/reset_password", params)
        expect(response.status).to eq 400
        expect(json_response.errors).not_to be_empty
      end
    end
  end

  describe "GET /api/n26/freyr/customer/:migration_token" do
    context "when customer exists for given token" do
      let(:migration_token) { SecureRandom.alphanumeric(16) }
      let!(:mandate) {
        create(
          :mandate,
          :freyr_with_data,
          :with_phone,
          migration_token: migration_token,
          migration_state: N26::Constituents::Freyr::Entities::Customer::State::PHONE_ADDED
        )
      }

      it "returns 200 code and customer data" do
        json_get_v5("/api/n26/freyr/customer/#{migration_token}")
        phone_details = TelephoneNumber.parse(mandate.phone)
        expect(response.status).to eq 200
        expect(json_response["data"]["id"]).to eq(mandate.id)
        expect(json_response["data"]["attributes"]["migration_state"]).to eq(mandate.info["freyr"]["migration_state"])
        expect(json_response["data"]["attributes"]["phone"]["country_code"]).to eq(phone_details.country.country_code)
        expect(json_response["data"]["attributes"]["phone"]["number"]).to eq(phone_details.normalized_number)
      end
    end

    context "when customer doesn't exists for given token" do
      let(:migration_token) { SecureRandom.alphanumeric(16) }

      it "returns 404" do
        json_get_v5("/api/n26/freyr/customer/#{migration_token}")

        expect(response.status).to eq 404
      end
    end
  end
end
