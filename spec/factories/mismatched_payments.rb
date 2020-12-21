# frozen_string_literal: true

FactoryBot.define do
  factory :mismatched_payment do
    sequence(:first_name) { |n| "John#{n}" }
    last_name { "Roe" }
    amount_cents { 1000 }
    amount_currency { "EUR" }
    settlement_date { 1.day.ago }
    transaction_type { "initial_commission" }
    reference_number { "123456" }
    number { "6554213" }
    reason { "product_is_not_valid" }
    cost_center
  end
end
