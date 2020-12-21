# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PartnersController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/partners")) }
  let(:admin) { create(:admin, role: role) }
  let!(:partner) { create(:partner) }

  before { login_admin(admin) }

  describe "GET #index" do
    it "returns only the correct plans" do
      get :index, params: {locale: :de}
      expect(response).to have_http_status(:ok)
      expect(assigns(:partners)).to match_array([partner])
    end
  end
end
