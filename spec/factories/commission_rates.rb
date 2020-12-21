# frozen_string_literal: true

FactoryBot.define do
  factory :commission_rate do
    pool { :fonds_finanz }
    rate { 23 }

    trait :with_subcompany do
      association :subcompany
    end

    trait :with_category do
      association :category
    end
  end
end
