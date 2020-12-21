# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_products
#
#  id                                                     :integer          not null, primary key
#  category                                               :integer          default("undefined"), not null
#  document_date                                          :date
#  retirement_date                                        :date
#  guaranteed_pension_continueed_payment_cents            :integer          default(0), not null
#  guaranteed_pension_continueed_payment_currency         :string           default("EUR"), not null
#  guaranteed_pension_continueed_payment_monthly_currency :string           default("EUR"), not null
#  guaranteed_pension_continueed_payment_payment_type     :integer          default("monthly"), not null
#  surplus_retirement_income_cents                        :integer          default(0), not null
#  surplus_retirement_income_currency                     :string           default("EUR"), not null
#  surplus_retirement_income_monthly_currency             :string           default("EUR"), not null
#  surplus_retirement_income_payment_type                 :integer          default("monthly"), not null
#  retirement_three_percent_growth_cents                  :integer          default(0), not null
#  retirement_three_percent_growth_currency               :string           default("EUR"), not null
#  retirement_three_percent_growth_monthly_currency       :string           default("EUR"), not null
#  retirement_three_percent_growth_payment_type           :integer          default("monthly"), not null
#  retirement_factor_cents                                :integer          default(0), not null
#  retirement_factor_currency                             :string           default("EUR"), not null
#  retirement_factor_monthly_currency                     :string           default("EUR"), not null
#  retirement_factor_payment_type                         :integer          default("monthly"), not null
#  fund_capital_three_percent_growth_cents                :integer          default(0), not null
#  fund_capital_three_percent_growth_currency             :string           default("EUR"), not null
#  guaranteed_capital_cents                               :integer          default(0), not null
#  guaranteed_capital_currency                            :string           default("EUR"), not null
#  equity_today_cents                                     :integer          default(0), not null
#  equity_today_currency                                  :string           default("EUR"), not null
#  possible_capital_including_surplus_cents               :integer          default(0), not null
#  possible_capital_including_surplus_currency            :string           default("EUR"), not null
#  pension_capital_today_cents                            :integer          default(0), not null
#  pension_capital_today_currency                         :string           default("EUR"), not null
#  pension_capital_three_percent_cents                    :integer          default(0), not null
#  pension_capital_three_percent_currency                 :string           default("EUR"), not null
#  created_at                                             :datetime         not null
#  updated_at                                             :datetime         not null
#  type                                                   :string
#  product_id                                             :integer
#  state                                                  :string
#  forecast                                               :integer          default("document")
#

require "rails_helper"

RSpec.describe Retirement::CorporateProduct, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  # Associations
  # Nested Attributes
  # Validations
  context "all types of corporate product" do
    subject(:product) { FactoryBot.build_stubbed(:retirement_corporate_product, state: :details_available) }

    it "validates presence of retirement_date" do
      expect(subject).to validate_presence_of(:retirement_date)
    end
  end

  # Callbacks
  # Instance Methods
  # Class Methods

  context "direktversicherung_classic" do
    subject(:product) { FactoryBot.build_stubbed(:retirement_corporate_product, :direktversicherung_classic) }

    describe "#ordered_permitted_fields" do
      it "should return correct permitted fields" do
        expect(product.ordered_permitted_fields).to match_array(
          %i[
            state
            retirement_date
            document_date
            surplus_retirement_income
            surplus_retirement_income_payment_type
          ]
        )
      end
    end
  end

  context "direktversicherung_fonds" do
    subject(:product) { FactoryBot.build_stubbed(:retirement_corporate_product, :direktversicherung_fonds) }

    describe "#ordered_permitted_fields" do
      it "should return correct permitted fields" do
        expect(product.ordered_permitted_fields).to match_array(
          %i[
            state
            retirement_date
            document_date
            guaranteed_pension_continueed_payment
            guaranteed_pension_continueed_payment_payment_type
            retirement_three_percent_growth
            retirement_three_percent_growth_payment_type
          ]
        )
      end
    end
  end

  context "pensionskasse" do
    subject(:product) { FactoryBot.build_stubbed(:retirement_corporate_product, :pensionskasse) }

    describe "#ordered_permitted_fields" do
      it "should return correct permitted fields" do
        expect(product.ordered_permitted_fields).to match_array(
          %i[
            state
            retirement_date
            document_date
            guaranteed_pension_continueed_payment
            guaranteed_pension_continueed_payment_payment_type
            surplus_retirement_income
            surplus_retirement_income_payment_type
          ]
        )
      end
    end
  end

  context "unterstuetzungskasse" do
    subject(:product) { FactoryBot.build_stubbed(:retirement_corporate_product, :unterstuetzungskasse) }

    describe "#ordered_permitted_fields" do
      it "should return correct permitted fields" do
        expect(product.ordered_permitted_fields).to match_array(
          %i[
            state
            retirement_date
            document_date
            guaranteed_pension_continueed_payment
            guaranteed_pension_continueed_payment_payment_type
            surplus_retirement_income
            surplus_retirement_income_payment_type
          ]
        )
      end
    end
  end

  context "direktzusage" do
    subject(:product) { FactoryBot.build_stubbed(:retirement_corporate_product, :direktzusage) }

    describe "#ordered_permitted_fields" do
      it "should return correct permitted fields" do
        expect(product.ordered_permitted_fields).to match_array(
          %i[
            state
            retirement_date
            pension_capital_today
            pension_capital_three_percent
          ]
        )
      end
    end
  end

  context "pensionsfonds" do
    subject(:product) { FactoryBot.build_stubbed(:retirement_corporate_product, :pensionsfonds) }

    describe "#ordered_permitted_fields" do
      it "should return correct permitted fields" do
        expect(product.ordered_permitted_fields).to match_array(
          %i[
            state
            retirement_date
            guaranteed_pension_continueed_payment
            guaranteed_pension_continueed_payment_payment_type
            surplus_retirement_income
            surplus_retirement_income_payment_type
          ]
        )
      end
    end
  end
end
