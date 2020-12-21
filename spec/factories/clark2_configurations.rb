# frozen_string_literal: true

FactoryBot.define do
  factory :clark2_configuration do
    trait :ios_probability do
      key { :ios_probability }
      value { "0" }
    end

    trait :android_probability do
      key { :android_probability }
      value { "0" }
    end

    trait :other_probability do
      key { :other_probability }
      value { "0" }
    end
  end
end
