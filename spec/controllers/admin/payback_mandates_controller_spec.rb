# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PaybackMandatesController, :integration, type: :controller do
  let(:role) { create(:role, permissions: Permission.where(controller: "admin/payback_mandates")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "GET failed_on_sanity_check" do
    let!(:failed_on_sanity_check_mandate) {
      create(
        :mandate,
        :payback_with_data,
        loyalty: {
          payback: {
            "paybackNumber" => Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX),
            "rewardedPoints" => {
              "locked" => 750,
              "unlocked" => 0
            },
            "sanity_check" => {
              "result" => false,
              "expected_points_amount" => 1500
            }
          }
        }
      )
    }

    let(:payback_mandate) { create(:mandate, :payback_with_data) }

    it "responds with success and assigns correct mandates" do
      get :failed_on_sanity_check, params: { locale: I18n.locale }

      expect(response).to have_http_status(:ok)
      expect(assigns(:mandates)).to match_array([failed_on_sanity_check_mandate])
    end
  end

  describe "POST run_sanity_check" do
    it "enqueues Payback::Jobs::RunSanityCheckJob" do
      expect(Payback::Jobs::RunSanityCheckJob).to receive(:perform_later)

      post :run_sanity_check, params: { locale: I18n.locale }

      expect(response).to have_http_status(:redirect)
    end
  end
end
