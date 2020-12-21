# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::BusinessEventsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/business_events")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  # Concerns
  # Filter

  context "check_access_flag" do
    let!(:mandate) { create(:mandate) }

    it "redirects to the admin root with an error when flag is not set" do
      get :index, params: {mandate_id: mandate.id, locale: :de}

      expect(response).to redirect_to([:admin, mandate])
      expect(controller).to set_flash[:alert].to("Kein Zugriff!")
    end
  end

  # Actions
end
