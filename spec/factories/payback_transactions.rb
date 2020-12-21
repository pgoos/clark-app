# frozen_string_literal: true

FactoryBot.define do
  factory :payback_transaction do
    association :mandate, :payback_with_data
    points_amount { 20 }
    state { "created" }
    info { {} }

    trait :book do
      receipt_no { "1-1-I" }
      transaction_type { "book" }
      locked_until { DateTime.now + 14.days }
    end

    trait :refund do
      receipt_no { "1-1-I" }
      transaction_type { "refund" }
      locked_until { DateTime.now + 14.days }
    end

    trait :with_inquiry_category do
      association :subject, factory: [:inquiry_category]
    end
  end
end
