# frozen_string_literal: true

# == Schema Information
#
# Table name: offer_automations
#
#  id                              :integer          not null, primary key
#  name                            :string
#  state                           :string           default("inactive")
#  questionnaire_id                :integer
#  default_coverage_feature_idents :string           default([]), is an Array
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#

FactoryBot.define do
  factory :offer_automation do
    sequence(:name) { |n| "automation name #{n}" }
    note_to_customer { Faker::Lorem.paragraph }
    default_coverage_feature_idents { %w[ident1 ident2 ident3] }
    association :questionnaire, factory: :questionnaire

    trait :active do
      state { "active" }
    end
  end
end
