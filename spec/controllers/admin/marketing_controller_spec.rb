# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MarketingController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/marketing")) }
  let(:admin) { create(:admin, role: role) }

  # Settings
  # ---------------------------------------------------------------------------------------

  # Concerns
  # ---------------------------------------------------------------------------------------

  # Filter
  # ---------------------------------------------------------------------------------------

  # Actions
  # ---------------------------------------------------------------------------------------

  describe "GET #overview" do
    before do
      sign_in(admin)
    end

    it "returns http success" do
      get :overview, params: {locale: :de}
      expect(response).to have_http_status(:success)
    end
  end
end
