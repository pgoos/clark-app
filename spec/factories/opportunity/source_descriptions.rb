# frozen_string_literal: true

FactoryBot.define do
  factory :opportunity_source_description, class: "Opportunity::SourceDescription" do
    description { Faker::Lorem.paragraph }
  end
end
