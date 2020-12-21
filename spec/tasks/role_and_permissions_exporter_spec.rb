# frozen_string_literal: true

require "rails_helper"

RSpec.describe "role_and_permissions_exporter:import", type: :task do
  let(:main_struct) do
    {
      admins: admins_struct,
      roles: roles_struct,
      permissions: permissions_struct
    }
  end

  let(:admins_struct) { [] }

  let(:roles_struct) do
    [
      role_attributes.merge(
        permissions: [permission_attributes]
      )
    ]
  end

  let(:permissions_struct) do
    [permission_attributes]
  end

  let(:role_identifier) { "role_identifier_1" }

  let(:role_attributes) do
    {
      identifier: role_identifier,
      name: "Role1",
      weight: 10
    }
  end

  let(:permission_attributes) do
    {
      controller: "admin/controller1",
      action: "action1"
    }
  end

  let(:created_role) do
    Role.find_by(identifier: role_identifier)
  end

  before do
    allow(File).to receive(:read).and_return(main_struct.to_json)
  end

  context "when role exists" do
    let!(:existing_role) do
      create(
        :role,
        skip_set_identifier: true,
        name: "Role2",
        weight: 12,
        identifier: role_identifier,
        permissions: [
          build(
            :permission,
            controller: "admin/controller2",
            action: "action2"
          )
        ]
      )
    end

    it "updates exactly existing role" do
      task.invoke
      expect(existing_role.id).to eq(created_role.id)
    end

    it "updates existing role attributes" do
      task.invoke

      expect(existing_role.reload.attributes).to(
        include(role_attributes.stringify_keys)
      )
    end

    it "updates existing role permissions" do
      task.invoke

      existing_role.reload
      expect(existing_role.permissions.count).to eq(1)
      expect(existing_role.permissions.first.attributes).to(
        include(permission_attributes.stringify_keys)
      )
    end

    describe "admin structure checking" do
      let(:admin_email) { "admin1@example.com" }

      context "when admins structure is empty" do
        let!(:existing_admin) do
          create(:admin, email: admin_email, role: existing_role)
        end

        it "updates existing role admin's permissions" do
          task.invoke

          expect(existing_admin.permissions.count).to eq(1)
          expect(existing_admin.permissions.first.attributes).to(
            include(permission_attributes.stringify_keys)
          )
        end
      end

      context "when admins structure isn't empty" do
        let(:admins_struct) do
          [
            {
              email: admin_email,
              role_identifier: role_identifier
            }
          ]
        end

        context "when admin has different role" do
          let(:another_role) do
            create(
              :role,
              name: "Role2",
              identifier: "role2"
            )
          end

          let!(:existing_admin) do
            create(
              :admin,
              email: admin_email,
              role: another_role
            )
          end

          it "changes existing admin role" do
            task.invoke
            expect(existing_admin.reload.role).to eq(created_role)
          end

          it "changes existing admin permissions" do
            task.invoke

            expect(existing_admin.permissions.count).to eq(1)
            expect(existing_admin.permissions.first.attributes).to(
              include(permission_attributes.stringify_keys)
            )
          end
        end
      end
    end
  end

  context "when role doesn't exist" do
    it "creates a role" do
      task.invoke

      expect(created_role.attributes).to(
        include(role_attributes.stringify_keys)
      )
    end

    it "creates a role permission" do
      task.invoke

      expect(created_role.permissions.count).to eq(1)
      expect(created_role.permissions.first.attributes).to(
        include(permission_attributes.stringify_keys)
      )
    end
  end
end
