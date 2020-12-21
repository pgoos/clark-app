# frozen_string_literal: true

require "rails_helper"

describe Domain::Retirement::Products::Create::CustomerInput do
  describe "#call" do
    subject { described_class.new(mandate) }

    let(:mandate)    { create :mandate }
    let(:category)   { create :category, :basis_classic }
    let(:company)    { create :company }
    let(:subcompany) { create :subcompany, company: company }

    let(:params) do
      {
        product: {
          premium_price: 134.45,
          premium_period: "month"
        },
        retirement_product: {
          retirement_date: Date.parse("01.01.2052"),
          retirement_three_percent_growth: 33,
          retirement_three_percent_growth_payment_type: "monthly",
          guaranteed_capital: 150_000,
          retirement_factor: 35.70,
          retirement_factor_payment_type: "monthly",
          fund_capital_three_percent_growth: 84_214
        }
      }
    end

    it "creates a dummy plan" do
      product = subject.(category, subcompany, params)
      plan = product.plan
      expect(plan).to be_present
      expect(plan.category).to eq category
      expect(plan.company).to eq company
      expect(plan.state).to eq "inactive"
      expect(plan.name).to eq "#{category.name} #{subcompany.name}"
    end

    it "creates a new product" do
      product = subject.(category, subcompany, params)
      expect(product).to be_present
      expect(product.premium_price.to_f).to eq 134.45
      expect(product.premium_period).to eq "month"
    end

    it "creates a new retirement product" do
      product = subject.(category, subcompany, params)
      retirement_product = product.retirement_product
      expect(retirement_product).to be_kind_of Retirement::PersonalProduct
      expect(retirement_product.category).to eq "basis_classic"
      expect(retirement_product.retirement_date).to eq Date.parse("01.01.2052")
      expect(retirement_product.retirement_three_percent_growth).to be_present
      expect(retirement_product.retirement_three_percent_growth_payment_type).to eq "monthly"
      expect(retirement_product.guaranteed_capital).to be_present
      expect(retirement_product.retirement_factor).to be_present
      expect(retirement_product.retirement_factor_payment_type).to eq "monthly"
      expect(retirement_product.fund_capital_three_percent_growth).to be_present
    end

    context "when 'dummy' plan for given category and subcompany already exists" do
      let!(:plan) do
        create :plan,
               :deactivated,
               name: "#{category.name} #{subcompany.name}",
               category: category,
               company: company,
               subcompany: subcompany
      end

      it "does not create a new one" do
        product = subject.(category, subcompany, params)
        expect(product.plan).to eq plan
      end
    end

    context "when an active plan for given category and subcompany already exists" do
      let!(:plan) do
        create :plan,
               :activated,
               name: "#{category.name} #{subcompany.name}",
               category: category,
               company: company,
               subcompany: subcompany
      end

      it "does not create a new one" do
        product = subject.(category, subcompany, params)
        expect(product.plan).to eq plan
      end
    end
  end
end
