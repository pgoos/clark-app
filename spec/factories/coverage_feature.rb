FactoryBot.define do
  factory :coverage_feature do
    sequence(:identifier)  { |n| "cvrgftr#{n}" }
    name { "Coverage Feature" }
    definition { "Some description" }
    value_type { 'Money' }
    valid_from { DateTime.new(2015,1,1,12,0,0) }
    valid_until { nil }
    section { "Any section" }
    description { "Description" }

    factory :coverage_feature_deckungssumme do
      identifier { 'deckungssumme' }
      name { 'Deckungssumme' }
      value_type { 'Money' }
    end

    trait :active do
      valid_until { Date.tomorrow }
    end

    trait :inactive do
      valid_until { Date.yesterday }
    end
  end
end
