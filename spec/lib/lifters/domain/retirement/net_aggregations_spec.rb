# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::NetAggregations do
  let(:mandate)  { object_double Mandate.new, birthdate: Date.new(1990, 1, 1) }
  let(:products) { [product1, product2, product3] }

  let(:product1) do
    object_double(
      Retirement::CalculatableProductDecorator.new(Retirement::Product.new),
      category_ident: "e97a99d7",
      gross_income: Money.new(0.0),
      taxable_income_pre_deductibles: Money.new(0.0),
      taxable_income_post_deductibles: Money.new(0.0),
      document_date: Date.new(2005, 1, 1)
    )
  end

  let(:product2) do
    object_double(
      Retirement::CalculatableProductDecorator.new(Retirement::Product.new),
      category_ident: "e97a99d7",
      gross_income: Money.new(20000),
      taxable_income_pre_deductibles: Money.new(18000),
      taxable_income_post_deductibles: Money.new(12000),
      document_date:  Date.new(2005, 1, 1)
    )
  end

  let(:product3) do
    object_double(
      Retirement::CalculatableProductDecorator.new(Retirement::Product.new),
      category_ident: "f0a0e78c",
      gross_income: Money.new(300000),
      taxable_income_pre_deductibles: Money.new(28000),
      taxable_income_post_deductibles: Money.new(210000),
      document_date: Date.new(2005, 1, 1)
    )
  end

  before do
    allow(Domain::Retirement::Tax::Deductibles).to \
      receive(:for_products).with([product2, product3]).and_return(->(_) { 900 })
  end

  it "calculates deductibles base on taxation type" do
    result = described_class.(mandate, products)
    expect(result.deductibles).to be_kind_of Money
    expect(result.deductibles.to_f).to eq 9.0
  end

  it "calculates total taxable income" do
    result = described_class.(mandate, products)
    expect(result.total_taxable_income_post_deductibles).to be_kind_of Money
    expect(result.total_taxable_income_post_deductibles.to_f).to eq 2220.0
  end

  it "calculates number of retirement products with positive income" do
    result = described_class.(mandate, products)
    expect(result.products_with_income_count).to eq 2
  end
end
