# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_products
#
#  id                                                     :integer          not null, primary key
#  category                                               :integer          default("vermoegen"), not null
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

RSpec.describe Retirement::EquityProduct, type: :model do
  # Setup
  subject(:product) { FactoryBot.build_stubbed(:retirement_equity_product) }

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
  # Callbacks
  # Instance Methods
  describe "#ordered_permitted_fields" do
    it "should return correct permitted fields" do
      expect(product.ordered_permitted_fields).to match_array(
        %i[
          state
          equity_today
        ]
      )
    end
  end

  # Class Methods
end
