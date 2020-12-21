# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id                                    :integer          not null, primary key
#  plan_id                               :integer
#  inquiry_id                            :integer
#  state                                 :string
#  number                                :string
#  premium_price_cents                   :integer          default(0)
#  premium_price_currency                :string
#  premium_period                        :string
#  contract_started_at                   :datetime
#  contract_ended_at                     :datetime
#  portfolio_commission_price_cents      :integer
#  portfolio_commission_price_currency   :string
#  portfolio_commission_period           :string           default("year")
#  acquisition_commission_price_cents    :integer
#  acquisition_commission_price_currency :string
#  acquisition_commission_period         :string           default("year")
#  acquisition_commission_payouts_count  :integer
#  acquisition_commission_conditions     :text
#  created_at                            :datetime
#  updated_at                            :datetime
#  mandate_id                            :integer
#  notes                                 :string
#  premium_state                         :string           default("premium")
#  coverages                             :jsonb            not null
#  turnover_possible                     :boolean
#  insurance_holder                      :string           default("customer")
#  rating                                :integer
#  renewal_period                        :integer
#  annual_maturity                       :string
#  managed_by_pool                       :string
#  means_of_payment                      :string           default("DIRECT_DEBITING")
#  qualitypool_id                        :integer
#  takeover_requested_at                 :datetime
#  cancellation_reason                   :string
#  takeover_possible                     :boolean
#  sold_by                               :string
#

FactoryBot.define do
  factory :product do
    sequence(:number) { |n| "#{SecureRandom.hex(6)}-#{n}" }
    contract_started_at { DateTime.new(2009, 1, 2, 0, 0, 0) }
    premium_price { Money.new(100_00, "EUR") }
    premium_period { "month" }
    premium_state { "premium" }
    cancellation_reason { "" }
    portfolio_commission_price { Money.new(5_00, "EUR") }
    portfolio_commission_period { "year" }
    association :plan, strategy: :build
    mandate

    factory :product_gkv do
      association :plan, factory: :plan_gkv
      premium_state { "salary" }
      premium_period { "none" }
      premium_price { Money.new(0, "EUR") }
    end

    factory :product_with_insurance_tax do
      association :plan, :with_insurance_tax
    end

    trait :publishable do
      # ensures that the trough plan associations are available
      association :plan, strategy: :create
      category { plan.category }
      company { plan.company }
    end

    trait :shallow do
      plan { nil }
      mandate { nil }
    end

    trait :customer_provided do
      state { :customer_provided }
    end

    trait :under_management do
      state { :under_management }
    end

    trait :takeover_requested do
      state { :takeover_requested }
    end

    trait :termination_pending do
      state { :termination_pending }
    end

    trait :ordered do
      state { :ordered }
    end

    trait :details_complete do
      analysis_state { :details_complete }
    end

    trait :details_missing do
      analysis_state { :details_missing }
    end

    trait :correspondence do
      state { :correspondence }
    end

    trait :cheap_product do
      premium_price { Money.new(10_00, "EUR") }
    end

    trait :retirement_state_category do
      association :category, :state
    end

    trait :retirement_personal_category do
      association :category, :overall_personal
    end

    trait :retirement_personal_category do
      association :category, :equity
    end

    trait :retirement_state_product do
      association :retirement_product, factory: [:retirement_state_product]
      association :category, :state
    end

    trait :retirement_equity_product do
      association :retirement_product, factory: [:retirement_equity_product]
      association :category, :equity
    end

    trait :retirement_overall_personal_product do
      association :retirement_product, factory: :retirement_personal_product, category: "kapitallebensversicherung"
      association :category, ident: "c187d55b"
    end

    trait :retirement_equity_category do
      association :category, :equity
    end

    trait :suhk_product do
      association :category, :suhk
    end

    trait :with_advisory_documentation do
      after(:create) do |product|
        product.documents << build(:document, :advisory_documentation)
      end
    end

    trait :with_cover_note do
      after(:create) do |product|
        product.documents << build(:document, :cover_note)
      end
    end

    trait :with_customer_uploaded_document do
      after(:create) do |product|
        product.documents << build(:document, :customer_upload)
      end
    end

    trait :retirement_combo_product do
      association :category, :retirement_combo_category_equity
    end

    trait :state do
      association :category, :state
    end

    trait :month_premium do
      premium_period { "month" }
    end

    trait :once_premium do
      premium_period { "once" }
    end

    trait :year_premium do
      premium_period { "year" }
    end

    trait :details_available do
      state { :details_available }
    end

    trait :order_pending do
      state { :order_pending }
    end

    trait :ordered do
      state { :ordered }
    end

    trait :terminated do
      state { :terminated }
    end

    trait :offered do
      state { :offered }
    end

    trait :correspondence do
      state { :correspondence }
    end

    trait :canceled_by_customer do
      state { :canceled_by_customer }
    end

    trait :canceled do
      state { :canceled }
    end

    trait :with_sales_fee do
      acquisition_commission_price_cents { 20000 }
      acquisition_commission_price_currency { "EUR" }
      acquisition_commission_period { "year" }
      acquisition_commission_payouts_count { 1 }
      acquisition_commission_conditions { "" }
    end

    trait :sold_by_us do
      sold_by { "us" }
    end

    trait :sold_by_others do
      sold_by { "others" }
    end

    trait :direktversicherung do
      association :category, :direktversicherung
    end

    trait :with_retirement_product do
      association :retirement_product, factory: [:retirement_state_product]
    end

    trait :phv do
      association :category, factory: [:category_phv]
    end

    factory :shallow_product do
      shallow

      to_create { |opportunity| opportunity.save(validate: false) }
    end

    trait :with_advice do
      after(:create) do |product|
        create(:advice, :created_by_robo_advisor, product: product, created_at: 9.months.ago)
      end
    end

    trait :shared_contract do
      insurance_holder { :third_party }
    end
  end
end
