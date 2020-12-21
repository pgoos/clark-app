# frozen_string_literal: true

require "rails_helper"

RSpec.describe ComfyAdminAuthorization, type: :request do
  # Setup
  let(:current_admin) { build(:admin, role: build(:role)) }

  describe "unpermitted route redirection" do
    before do
      login_as(current_admin, scope: :admin)
    end

    context "when admin has access" do
      before do
        current_admin.permissions << Permission.find_by(controller: "comfy/admin/cms/pages", action: "index")
      end

      it "allows access, does not redirect" do
        get "/de/admin/cms/sites/1/pages"
        expect(response).to be_ok
      end
    end

    context "when admin does not have access" do
      it "redirects to admin root" do
        get "/de/admin/cms/sites/1/pages"
        expect(response).to redirect_to(%i[admin root])
      end
    end
  end
end
