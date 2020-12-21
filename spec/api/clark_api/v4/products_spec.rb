# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Products, :integration do
  let(:user) { create :user, mandate: mandate }
  let(:mandate) { create :mandate }

  describe "DELETE /api/products/:product_id/cancel" do
    let(:product) { create :product, :details_available, mandate: mandate }

    context "when customer is not authenticated" do
      it "responds with an error" do
        json_delete_v4 "/api/products/#{product.id}/cancel"
        expect(response.status).to eq 401
      end
    end

    context "when product does not exist or does not belong to customer" do
      let(:product) { create :product, :details_available, :sold_by_us }

      it "responds with an error" do
        login_as(user, scope: :user)

        json_delete_v4 "/api/products/#{product.id}/cancel"
        expect(response.status).to eq 404

        json_delete_v4 "/api/products/99999/cancel"
        expect(response.status).to eq 404
      end
    end

    it "cancels the product" do
      login_as(user, scope: :user)
      json_delete_v4 "/api/products/#{product.id}/cancel"
      expect(response.status).to eq 204
      expect(product.reload).to be_terminated
    end

    context "when product is non detailed one" do
      let(:product) { create :product, :customer_provided, mandate: mandate, number: nil }

      it "cancels the product" do
        login_as(user, scope: :user)
        json_delete_v4 "/api/products/#{product.id}/cancel"
        expect(response.status).to eq 204
        expect(product.reload).to be_terminated
      end
    end
  end
end
