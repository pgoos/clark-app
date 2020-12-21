# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::RolesController, :integration, type: :controller do
  let(:role2)  { create(:role, permissions: Permission.where(controller: "admin/roles")) }
  let(:admin) { create(:admin, role: role2) }

  before { sign_in(admin) }

  describe "PATCH update" do
    let(:role)                { create :role }
    let(:permission)          { create :permission }
    let(:scope_authorization) { create :scope_authorization }

    context "with a simple update" do
      it "updates role, permissions, and scope authorizations" do
        patch :update,
              params: {
                locale: :de,
                id: role.id,
                role: {
                  name: "FOO_ROLE",
                  permission_ids: [permission.id],
                  scope_authorization_ids: [scope_authorization.id]
                }
              }

        expect(role.reload.name).to eq "FOO_ROLE"
        expect(role.permissions).to eq [permission]
        expect(role.scope_authorizations).to eq [scope_authorization]
      end
    end

    context "without nested attributes" do
      let(:role) { create(:role, permissions: [permission], scope_authorizations: [scope_authorization]) }

      it "sets permissions and scope_authorizations as empty array" do
        patch :update,
              params: {
                locale: :de,
                id: role.id,
                role: {
                  name: "FOO_ROLE"
                }
              }

        expect(role.reload.permissions).to eq []
        expect(role.reload.scope_authorizations).to eq []
      end
    end
  end

  describe "PATCH sync" do
    it "synchronizes permissions" do
      expect(Permission).to receive(:sync)
      patch :sync, params: {locale: :de}
      expect(response).to redirect_to admin_root_path
    end
  end

  describe "PATCH sync_and_permit" do
    before { request.env["HTTP_REFERER"] = admin_roles_path }

    it "synchronizes and permits admins" do
      expect(Permission).to receive(:sync_and_permit_admins!)
      patch :sync_and_permit, params: {locale: :de}
      expect(response).to redirect_to admin_roles_path
    end
  end
end
