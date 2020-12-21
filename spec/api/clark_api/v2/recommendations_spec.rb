# frozen_string_literal: true
require "rails_helper"

RSpec.describe ClarkAPI::V2::Recommendations, :integration do
  context "POST /api/mandates/:id/recommendations/:recommendation_id/dimiss" do
    let(:mandate) { create(:mandate) }
    let!(:recommendation) { create(:recommendation, mandate: mandate) }
    let(:user) { create(:user, mandate: mandate) }

    it "requires authentication" do
      logout
      json_patch_v2 "/api/mandates/#{mandate.id}/recommendations/#{recommendation.id}/dismiss"
      expect(response.status).to eq(401)
    end

    it "marks recommendation as dismmissed" do
      login_as(user, scope: :user)
      json_patch_v2 "/api/mandates/#{mandate.id}/recommendations/#{recommendation.id}/dismiss"

      expect(response.status).to eq(200)
      expect(Recommendation.first.dismissed).to eq(true)
    end

    it "raises 404 if non existing recommendation id is provided" do
      login_as(user, scope: :user)
      json_patch_v2 "/api/mandates/#{mandate.id}/recommendations/non-existent/dismiss"

      expect(response.status).to eq(404)
    end

  end
end
