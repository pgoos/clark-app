# frozen_string_literal: true

FactoryBot.define do
  factory :nps_cycle do
    maximum_score { "" }
    end_at { "2020-07-27 11:39:39" }

    trait :open do
      state { "OPEN" }
    end

    trait :closing do
      state { "CLOSING" }
    end

    trait :closed do
      state { "CLOSED" }
    end
  end
end
