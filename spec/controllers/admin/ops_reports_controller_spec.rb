# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::OpsReportsController, :integration, type: :request do
  let(:role) { create :role, permissions: Permission.where(controller: "admin/ops_reports") }
  let(:admin) { create :admin, role: role }

  describe "GET index" do
    context "when admin does not have permission" do
      it "redirect admin" do
        get admin_ops_reports_path(locale: :de)

        expect(response).to have_http_status(:found)
      end
    end

    context "when admin does have permission" do
      before { sign_in(admin) }

      it "respond with 200" do
        get admin_ops_reports_path(locale: :de)

        expect(response).to have_http_status(:ok)
      end

      context "when filtering with name" do
        let!(:ops_report) { create(:ops_report, name: "opportunities_wo_appointment") }

        it "returns documents with given name" do
          get admin_ops_reports_path(
            locale: :de,
            ops_reports: { name: ops_report.name }
          )
          expect(response.body).to include(ops_report.name)
        end
      end
    end
  end
end
