# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Mandates::InquiryCategories, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  before do
    login_as(admin, scope: :admin)
  end

  describe "GET /api/admin/mandates/:mandate_id/inquiry_categories" do
    let(:mandate) { create :mandate }
    let(:product) { create :product, mandate: mandate, inquiry: inquiry }
    let(:inquiry) { create :inquiry, mandate: mandate }

    let!(:inquiry_category1) { create :inquiry_category, inquiry: inquiry, category: product.category }
    let!(:inquiry_category2) { create :inquiry_category, inquiry: inquiry }

    it "returns all iquiry categories which are visible to customer" do
      json_admin_get_v1 "/api/admin/mandates/#{mandate.id}/inquiry_categories"

      expect(response.status).to eq(200)
      expect(json_response["inquiry_categories"]).to be_present
      expect(json_response["inquiry_categories"].size).to eq 1
      expect(json_response["inquiry_categories"][0]["id"].to_i).to eq inquiry_category2.id
    end
  end
end
