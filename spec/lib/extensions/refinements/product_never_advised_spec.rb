# frozen_string_literal: true

require "rails_helper"

require "extensions/refinements/product_never_advised"

RSpec.describe ProductNeverAdvised do
  let!(:product) { create(:product) }
  let!(:product_advised) { create(:product) }
  let!(:advice) { create(:advice, topic: product_advised) }

  describe "unrefined" do
    it "has one unadvised product" do
      expect(Product.unadviced.count).to eq(Product.count - 1)
    end

    it "has one advised product" do
      expect(Product.adviced.count).to eq(1)
    end
  end

  describe "refined" do
    it "has all products unadvised" do
      expect(ProductNeverAdvised.unadviced.count).to eq(Product.count)
    end

    it "has no product advised" do
      expect(ProductNeverAdvised.adviced.count).to eq(0)
    end
  end
end
