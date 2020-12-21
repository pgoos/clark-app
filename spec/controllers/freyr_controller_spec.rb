# frozen_string_literal: true

require "rails_helper"

RSpec.describe FreyrController, :integration, type: :controller do
  let(:token) { "Ko01234567891234" }
  let(:params) { { migration_token: token } }

  describe "GET funnel_router" do
    context "when mandate with migration token exists" do
      let!(:mandate) {
        create(
          :mandate,
          :freyr_with_data,
          migration_token: token,
          migration_state: "email_verified"
        )
      }

      it "assigns customer associated with the migration token" do
        get :funnel_router, params: params
        expect(assigns(:customer).id).to eq(mandate.id)
      end

      it "passes the migration_token on to the frontend" do
        get :funnel_router, params: params
        expect(subject.location).to match(/.*migration_token=#{token}/)
      end
    end

    context "when the mandate not in a valid funnel state" do
      let!(:mandate) {
        create(
          :mandate,
          :freyr_with_data,
          migration_token: token,
          migration_state: ""
        )
      }

      it "returns an unauthorised error" do
        get :funnel_router, params: params
        expect(subject).to redirect_to("/de/app/freyr?error_key=#{described_class::ERROR_KEYS[:customer_not_eligible]}")
      end
    end

    context "when the mandate is in 'email_verified' state" do
      let!(:mandate) {
        create(
          :mandate,
          :freyr_with_data,
          migration_token: token,
          migration_state: "email_verified"
        )
      }

      it "redirects to the phone-number URL" do
        get :funnel_router, params: params
        expect(subject).to redirect_to("/de/app/freyr/phone-number?migration_token=#{token}")
      end
    end

    context "when the mandate is in 'phone_added' state" do
      let!(:mandate) {
        create(
          :mandate,
          :freyr_with_data,
          migration_token: token,
          migration_state: "phone_added"
        )
      }

      it "redirects to the phone-verification URL" do
        get :funnel_router, params: params
        expect(subject).to redirect_to("/de/app/freyr/phone-verification?migration_token=#{token}")
      end
    end

    context "when the mandate is in 'phone_verified' state" do
      let!(:mandate) {
        create(
          :mandate,
          :freyr_with_data,
          migration_token: token,
          migration_state: "phone_verified"
        )
      }

      it "redirects to the password_reset URL" do
        get :funnel_router, params: params
        expect(subject).to redirect_to("/de/app/freyr/password-reset?migration_token=#{token}")
      end
    end

    context "when no mandate with migration token exists" do
      let(:invalid_params) { { migration_token: "123" } }

      it "returns a not found error" do
        get :funnel_router, params: invalid_params
        expect(subject).to redirect_to("/de/app/freyr?error_key=#{described_class::ERROR_KEYS[:token_not_found]}")
      end
    end

    context "when no migration token is passed" do
      let(:blank_params) { {} }

      it "returns a not found error" do
        get :funnel_router, params: blank_params
        expect(subject).to redirect_to("/de/app/freyr?error_key=#{described_class::ERROR_KEYS[:token_not_found]}")
      end
    end
  end
end
