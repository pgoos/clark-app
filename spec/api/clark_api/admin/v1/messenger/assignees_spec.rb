# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Messenger::Assignees, :integration do
  let(:admin) { create(:admin, role: create(:role)) }
  let(:inactive_admin) { create(:admin, :inactive, role: create(:role)) }

  before do
    login_as(admin, scope: :admin)
  end

  describe "GET /api/admin/messenger/assignees" do
    it "should get all active admins" do
      json_admin_get_v1 "/api/admin/messenger/assignees"

      expect(response.status).to eq(200)
      expect(json_response).to eq([{"id" => admin.id.to_s, "name" => admin.name}])
    end
  end

  describe "PUT /api/admin/messenger/:mandate_id/assignee" do
    let(:time) { Time.zone.now }
    let(:mandate) { create(:mandate) }
    let!(:message1) { create(:interaction_unread_received_message, mandate: mandate, created_at: time) }
    let!(:message2) { create(:interaction_unread_received_message, mandate: mandate, created_at: time - 1.hour) }
    let!(:message3) { create(:interaction_unread_received_message, mandate: mandate, created_at: time - 2.months) }

    context "admin_id has valid value" do
      it "should assign admin to all unread messages of mandate for the past 30 days" do
        json_admin_put_v1 "/api/admin/messenger/#{mandate.id}/assignee", admin_id: admin.id

        expect(response.status).to eq(200)
        expect(message1.reload.admin_id).to eq(admin.id)
        expect(message2.reload.admin_id).to eq(admin.id)
        expect(message3.reload.admin_id).to eq(nil)
      end
    end

    context "admin_id is empty" do
      it "should assign nil to all unread messages of mandate for the past 30 days" do
        json_admin_put_v1 "/api/admin/messenger/#{mandate.id}/assignee", admin_id: ""

        expect(response.status).to eq(200)
        expect(message1.reload.admin_id).to eq(nil)
        expect(message2.reload.admin_id).to eq(nil)
      end
    end
  end
end
