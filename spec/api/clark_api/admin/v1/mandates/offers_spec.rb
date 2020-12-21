# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Mandates::Offers, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  before do
    login_as(admin, scope: :admin)
  end

  describe "GET /api/admin/mandates/:mandate_id/offers" do
    let(:mandate) { create :mandate }
    let!(:offer1) { create :active_offer, mandate: mandate }
    let!(:offer2) { create :offer, :in_creation, mandate: mandate }

    it "returns all offers which are visible to customer" do
      json_admin_get_v1 "/api/admin/mandates/#{mandate.id}/offers"

      expect(response.status).to eq(200)
      expect(json_response["offers"]).to be_present
      expect(json_response["offers"].size).to eq 1
      expect(json_response["offers"][0]["id"].to_i).to eq offer1.id
    end
  end
end
