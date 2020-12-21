# frozen_string_literal: true

require "rails_helper"

describe Domain::Retirement::Products::RetirementProductBuilder do
  describe ".by_category" do
    it "builds an instance with category and specific class" do
      category = build_stubbed :category, :direktversicherung_classic
      product = described_class.by_category category
      expect(product).to be_kind_of Retirement::CorporateProduct
      expect(product.category).to eq "direktversicherung_classic"
    end
  end
end
