# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Classification::RevenueClassifier do
  let(:classifier) { described_class.new }
  let(:subcompany) { create(:subcompany, {revenue_generating: true}) }
  let(:product) { create(:product, subcompany: subcompany, state: "details_available") }

  context "is not revenue" do
    it "product does not have a subcompany" do
      product.subcompany = nil
      expect(classifier.classify(product)).to eq(:non_revenue)
    end

    it "product state is non revenue state" do
      product.update!(state: "takeover_denied")
      expect(classifier.classify(product)).to eq(:non_revenue)
    end

    it "product has a subcompany non revenue generating" do
      product.subcompany.update!(revenue_generating: false)

      expect(classifier.classify(product)).to eq(:non_revenue)
    end

  context "is revenue maker" do
    it "has right state and subcompany renvenue generating" do
      expect(classifier.classify(product)).to eq(:revenue)
    end
  end

    it "product has a subcompany non revenue generating" do
      product.subcompany.update!(revenue_generating: false)

      expect(classifier.classify(product)).to eq(:non_revenue)
    end
  end

  context "is revenue maker" do
    it "has right state and subcompany renvenue generating" do
      expect(classifier.classify(product)).to eq(:revenue)
    end

    it "product has a subcompany non revenue generating" do
      product.subcompany.update!(revenue_generating: false)

      expect(classifier.classify(product)).to eq(:non_revenue)
    end
  end

  context "is revenue maker" do
    it "has right state and subcompany renvenue generating" do
      expect(classifier.classify(product)).to eq(:revenue)
    end
  end
end
