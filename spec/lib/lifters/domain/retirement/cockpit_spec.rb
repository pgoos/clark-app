# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Cockpit do
  subject { described_class.new mandate, situation, products }

  let(:mandate) { object_double Mandate.new, retirement_cockpit: retirement_cockpit }
  let(:retirement_cockpit) { object_double Retirement::Cockpit.new, desired_income: Money.new(350000) }
  let(:products) { [] }
  let(:situation) { instance_double Domain::Situations::RetirementSituation }

  let(:net_aggregations) do
    double :net_aggregations,
           products_with_income_count: "PRODUCTS_WITH_INCOME_COUNT",
           deductibles: "DEDUCTIBLES",
           total_taxable_income_post_deductibles: "TOTAL_TAXABLE_INCOME"
  end

  before do
    allow(Domain::Retirement::NetAggregations).to receive(:call) \
      .with(mandate, Array).and_return net_aggregations
  end

  describe "#calculatable_products" do
    let(:retirement_product) { build_stubbed :retirement_product }
    let(:products) { [build_stubbed(:product, retirement_product: retirement_product)] }

    it "returns collection of decorated products" do
      expect(subject.calculatable_products.size).to eq 1
      expect(subject.calculatable_products.first).to be_kind_of Retirement::CalculatableProductDecorator
      expect(subject.calculatable_products.first.id).to eq retirement_product.id
    end
  end

  describe "#net_incomes" do
    let(:products) { [build_stubbed(:product)] }

    let(:calculatable_product) do
      double :calculatable_product, product_id: "PRODUCT_ID", net_income: 2_000
    end

    before do
      allow(Retirement::CalculatableProductDecorator).to receive(:from_products) \
        .with(products, situation).and_return([calculatable_product])
    end

    it "returns hash of calculated net incomes" do
      expect(calculatable_product).to receive(:net_income) \
        .with("DEDUCTIBLES", "TOTAL_TAXABLE_INCOME", "PRODUCTS_WITH_INCOME_COUNT")
      expect(subject.net_incomes).to eq("PRODUCT_ID" => 2_000)
    end
  end

  describe "#income_taxes" do
    let(:products) { [build_stubbed(:product)] }

    let(:calculatable_product) do
      double :calculatable_product, product_id: "PRODUCT_ID", income_tax: 500
    end

    before do
      allow(Retirement::CalculatableProductDecorator).to receive(:from_products) \
        .with(products, situation).and_return([calculatable_product])
    end

    it "returns hash of calculated income taxes" do
      expect(calculatable_product).to receive(:income_tax) \
        .with("DEDUCTIBLES", "TOTAL_TAXABLE_INCOME", "PRODUCTS_WITH_INCOME_COUNT")
      expect(subject.income_taxes).to eq("PRODUCT_ID" => 500)
    end
  end

  describe "#total_gross_income" do
    let(:products) { [build_stubbed(:product), build_stubbed(:product)] }

    let(:calculatable_products) do
      [
        double(:calculatable_product, gross_income: 100),
        double(:calculatable_product, gross_income: 2000)
      ]
    end

    before do
      allow(Retirement::CalculatableProductDecorator).to receive(:from_products) \
        .with(products, situation).and_return(calculatable_products)
    end

    it "returns total gross income" do
      expect(subject.total_gross_income).to eq 2100
    end
  end

  describe "#total_net_income" do
    let(:products) { [build_stubbed(:product), build_stubbed(:product)] }

    let(:calculatable_products) do
      [
        double(:calculatable_product, product_id: 1, net_income: 50),
        double(:calculatable_product, product_id: 2, net_income: 1500)
      ]
    end

    before do
      allow(Retirement::CalculatableProductDecorator).to receive(:from_products) \
        .with(products, situation).and_return(calculatable_products)
    end

    it "returns total net income" do
      expect(subject.total_net_income).to eq 1550
    end
  end

  describe "#recommended_income" do
    it "calculates recommended income" do
      expect(Domain::Retirement::Estimations::RecommendedIncome::Net).to \
        receive(:for_mandate).with(mandate).and_return(-> { 400_000 })
      expect(subject.recommended_income.to_f).to eq 4_000.0
    end
  end

  describe "#desired_income" do
    it "returns customer's desired income" do
      expect(subject.desired_income).to eq Money.new(350000)
    end
  end

  describe "#retirement_gap" do
    let(:products) { [build_stubbed(:product), build_stubbed(:product)] }

    let(:calculatable_products) do
      [
        double(:calculatable_product, product_id: 1, net_income: 200),
        double(:calculatable_product, product_id: 2, net_income: 1500)
      ]
    end

    before do
      allow(Retirement::CalculatableProductDecorator).to receive(:from_products) \
        .with(products, situation).and_return(calculatable_products)
    end

    it "returns gap between desired and actual income" do
      expect(subject.retirement_gap).to eq 1_800
    end

    context "when desired income is zero" do
      let(:retirement_cockpit) { object_double Retirement::Cockpit.new, desired_income: nil }

      before do
        allow(Domain::Retirement::Estimations::RecommendedIncome::Net).to \
          receive(:for_mandate).with(mandate).and_return(-> { 400_000 })
      end

      it "returns gap between recommended and actual income" do
        expect(subject.retirement_gap).to eq 2_300
      end
    end
  end
end
