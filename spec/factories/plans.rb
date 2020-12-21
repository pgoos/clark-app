# frozen_string_literal: true
# == Schema Information
#
# Table name: plans
#
#  id                     :integer          not null, primary key
#  name                   :string
#  state                  :string
#  plan_state_begin       :date
#  out_of_market_at       :date
#  created_at             :datetime
#  updated_at             :datetime
#  coverages              :jsonb
#  category_id            :integer
#  company_id             :integer
#  subcompany_id          :integer
#  metadata               :jsonb
#  insurance_tax          :float
#  ident                  :string
#  premium_price_cents    :integer          default(0)
#  premium_price_currency :string           default("EUR")
#  premium_period         :string
#

FactoryBot.define do
  factory :plan do
    name { "#{Faker::Commerce.product_name} #{SecureRandom.alphanumeric(5)}" }
    plan_state_begin { Date.new(2018, 1) }
    association :subcompany, strategy: :create
    association :category, strategy: :build
    premium_price_cents { 5000 }
    premium_price_currency { "EUR" }
    premium_period { "month" }
    external_id { nil }

    transient do
      vertical { create(:vertical) }
    end

    factory :plan_gkv do
      association :category, factory: :category_gkv
      association :company, factory: :gkv_company
    end

    trait :shallow do
      category { nil }
      subcompany { nil }
      vertical { nil }
    end

    trait :deactivated do
      state { "inactive" }
    end

    trait :activated do
      state { "active" }
    end

    trait :with_insurance_tax do
      insurance_tax { 0.19 }
    end

    trait :suhk do
      association :category, :suhk
      association :company
    end

    trait :equity do
      ident { "cbfb0998" }
      name { "Vermoegen" }
      association :category, :equity
      association :company
    end

    trait :state do
      ident { "brdb0998" }
      name { "Gesetzliche Altersvorsorge" }
      association :category, :state
      association :company
    end

    trait :with_stubbed_coverages do
      association :subcompany
      category do
        association(
          :category,
          coverage_features: (
            (0..2).to_a.map do |i|
              build(:coverage_feature, identifier: "identifier_#{i}", value_type: "Text")
            end
          )
        )
      end
      coverages do
        (0..2).to_a.each_with_object({}) do |i, result|
          result["identifier_#{i}"] = ValueTypes::Text.new("Text #{i}")
        end
      end
    end

    trait :without_plan_state do
      plan_state_begin { nil }
    end
  end
end
