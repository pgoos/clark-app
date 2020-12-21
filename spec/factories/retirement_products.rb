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

FactoryBot.define do
  factory :retirement_product, class: "Retirement::Product" do
    product

    trait :state do
      category { 0 }
      type { "Retirement::StateProduct" }
      document_date { "01.01.2000" }
      guaranteed_pension_continueed_payment { 3000.0 }
      guaranteed_pension_continueed_payment_payment_type { "monthly" }
    end

    trait :shallow do
      product { nil }
    end

    trait :details_available do
      state { :details_available }
    end

    trait :information_required do
      state { :information_required }
    end

    trait :out_of_scope do
      state { :out_of_scope }
    end

    trait :initial_calculation do
      state

      forecast { :initial }
    end

    trait :out_of_scope do
      state { :out_of_scope }
    end

    trait :created do
      state { :created }
    end

    trait :information_required do
      state { :information_required }
    end

    trait :document_forecast do
      forecast { :document }
    end

    trait :initial_forecast do
      forecast { :initial }
    end

    trait :customer_forecast do
      forecast { :customer }
    end

    trait :direktversicherung_classic do
      type { "Retirement::CorporateProduct" }
      category { Retirement::CorporateProduct::CORPORATE.index(:direktversicherung_classic) }
    end

    trait :with_annual_values do
      surplus_retirement_income_cents { 3000.0 }
      surplus_retirement_income_payment_type { "annually" }

      retirement_three_percent_growth_cents { 3000.0 }
      retirement_three_percent_growth_payment_type { "annually" }

      retirement_factor_cents { 3000.0 }
      retirement_factor_payment_type { "annually" }

      guaranteed_pension_continueed_payment_cents { 3000.0 }
      guaranteed_pension_continueed_payment_payment_type { "annually" }
    end

    trait :with_monthly_values do
      surplus_retirement_income_cents { 3000.0 }
      surplus_retirement_income_payment_type { "monthly" }

      retirement_three_percent_growth_cents { 3000.0 }
      retirement_three_percent_growth_payment_type { "monthly" }

      retirement_factor_cents { 3000.0 }
      retirement_factor_payment_type { "monthly" }

      guaranteed_pension_continueed_payment_cents { 3000.0 }
      guaranteed_pension_continueed_payment_payment_type { "monthly" }
    end
  end
end
