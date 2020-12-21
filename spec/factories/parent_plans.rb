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
  factory :parent_plan do
    name { Faker::Commerce.product_name }
    plan_state_begin { Date.new(2018, 1) }
    association :subcompany, strategy: :create
    association :category, strategy: :build
    premium_price_cents { 5000 }
    premium_price_currency { "EUR" }
    premium_period { "month" }

    trait :deactivated do
      state { "inactive" }
    end

    trait :activated do
      state { "active" }
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
  end
end
