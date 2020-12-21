# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Tax::Deductibles do
  subject { described_class.(Date.parse("01.01.1985"), 300_000, 2) }

  let(:elderly) do
    instance_double(Domain::Retirement::ElderlyDeductible, call: 24000.0)
  end

  before do
    allow(Domain::Retirement::ElderlyDeductible).to receive(:new) { elderly }
  end

  it { expect(subject).to eq 1000.0 }

  describe ".for_products" do
    let(:products) { [product1, product2, product3] }

    let(:product1) do
      object_double(
        Retirement::CalculatableProductDecorator.new(Retirement::Product.new),
        category_ident: "e97a99d7",
        taxable_income_pre_deductibles: Money.new(0.0)
      )
    end

    let(:product2) do
      object_double(
        Retirement::CalculatableProductDecorator.new(Retirement::Product.new),
        category_ident: "e97a99d7",
        taxable_income_pre_deductibles: Money.new(18000)
      )
    end

    let(:product3) do
      object_double(
        Retirement::CalculatableProductDecorator.new(Retirement::Product.new),
        category_ident: "f0a0e78c",
        taxable_income_pre_deductibles: Money.new(28000)
      )
    end

    before do
      allow(Domain::Retirement::TaxationTypes).to receive(:for_product).with(product1).and_return :type2
      allow(Domain::Retirement::TaxationTypes).to receive(:for_product).with(product2).and_return :type1
      allow(Domain::Retirement::TaxationTypes).to receive(:for_product).with(product3).and_return :type3
    end

    it "calculates deductibles base on taxation type" do
      expect(described_class).to receive(:call).with(Date.new(1990, 1, 1), 18000, 2)
      described_class.for_products(products).(Date.new(1990, 1, 1))
    end
  end
end
