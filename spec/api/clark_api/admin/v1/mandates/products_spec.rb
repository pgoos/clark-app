# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Mandates::Products, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  before do
    login_as(admin, scope: :admin)
  end

  describe "GET /api/admin/mandates/:mandate_id/products" do
    let(:mandate)   { create :mandate }
    let!(:product1) { create :product, :canceled_by_customer, mandate: mandate }
    let!(:product2) { create :product, mandate: mandate }

    it "returns all products which are visible to customer" do
      json_admin_get_v1 "/api/admin/mandates/#{mandate.id}/products"

      expect(response.status).to eq(200)

      expect(json_response["products"]).to be_present
      expect(json_response["products"].size).to eq 1
      expect(json_response["products"][0]["id"].to_i).to eq product2.id
    end
  end
end
