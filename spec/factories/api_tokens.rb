# frozen_string_literal: true

FactoryBot.define do
  factory :api_token do
    token { "Test1234" }
    description { "Fake Token" }
  end
end
