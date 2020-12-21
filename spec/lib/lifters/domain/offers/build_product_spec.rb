# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Offers::BuildProduct do
  subject { Domain::Offers::BuildProduct.call(plan, product_attrs) }

  let(:active_coverage) { build(:coverage_feature, :active) }
  let(:inactive_coverage) { build(:coverage_feature, :inactive) }
  let(:category) { create(:category, coverage_features: [active_coverage, inactive_coverage]) }
  let(:coverages) do
    category.coverage_features.each_with_object({}) do |cf, result|
      result[cf.identifier] = ValueTypes::Text.new("Text #{cf.identifier}")
    end
  end

  let(:product_attrs) { {contract_started_at: Time.zone.now} }

  let(:plan) do
    create(:plan,
           coverages: coverages,
           category: category,
           premium_price_cents: 12_345,
           premium_price_currency: "EUR",
           premium_period: "month")
  end

  describe ".call" do
    it "build an offer product" do
      expect(subject).to be_a(Product)
      expect(subject.state).to eq("offered")
    end

    it "build product with correct values" do
      expect(subject.plan).to eq(plan)
      expect(subject.premium_price).to eq(plan.premium_price)
      expect(subject.premium_period).to eq(plan.premium_period)
      expect(subject.premium_state).to eq(plan.premium_state)
    end

    it "merges additional product attributes" do
      expect(subject.contract_started_at).to eq(product_attrs[:contract_started_at])
    end

    context "coverages" do
      it "only add active coverages" do
        expect(subject.coverages.count).to eq(1)
        expect(subject.coverages[active_coverage.identifier].present?).to eq(true)
      end

      it "assign empty hash if no coverage for plan" do
        plan.coverages = {}
        expect(subject.coverages).to eq({})
      end
    end
  end
end
