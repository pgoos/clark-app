# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Mandates::RecommendationsEndpoints, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  before do
    login_as(admin, scope: :admin)
  end

  describe "GET /api/admin/mandates/:mandate_id/recommendations" do
    let(:mandate) { create :mandate }
    let!(:recommendation) { create :recommendation, mandate: mandate }

    it "returns all recommendations which are visible to customer" do
      json_admin_get_v1 "/api/admin/mandates/#{mandate.id}/recommendations"

      expect(response.status).to eq(200)
      expect(json_response["recommendations"]).to be_present
      expect(json_response["recommendations"].size).to eq 1
      expect(json_response["recommendations"][0]["id"].to_i).to eq recommendation.id
    end
  end
end
