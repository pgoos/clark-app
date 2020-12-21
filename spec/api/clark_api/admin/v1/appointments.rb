# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Appointments, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  describe "GET /api/admin/appointments/opportunity/configuration" do
    context "when admin has logged in" do
      let!(:category) { create(:category) }
      let!(:source_description) { create(:opportunity_source_description) }
      let!(:sales_campaign) { create(:sales_campaign, :active) }

      before do
        login_as(admin, scope: :admin)
      end

      it "respond with neccessary data" do
        json_admin_get_v1("/api/admin/appointments/opportunity/configuration")

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(
          response_body["categories"]
        ).to eq([{ "id" => category.id.to_s, "ident" => category.ident, "name" => category.name }])
        expect(
          response_body["source_descriptions"]
        ).to eq([{ "id" => source_description.id.to_s, "description" => source_description.description }])
        expect(
          response_body["sales_campaigns"]
        ).to eq([{ "id" => sales_campaign.id.to_s, "name" => sales_campaign.name }])
      end
    end

    context "when admin has not logged in" do
      it "return 401 UNAUTHORIZED" do
        json_admin_get_v1("/api/admin/appointments/opportunity/configuration")

        expect(response.status).to eq(401)
      end
    end
  end
end
