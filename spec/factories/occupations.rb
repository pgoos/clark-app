# frozen_string_literal: true
# == Schema Information
#
# Table name: occupations
#
#  id       :integer          not null, primary key
#  ident    :string
#  name     :string
#  metadata :jsonb
#


FactoryBot.define do
  factory :occupation do
    sequence(:name) { |n| "job#{n}" }
    is_recommended_bu { false }
    is_recommended_du { false }

    trait :is_recommended_bu do
      is_recommended_bu { true }
    end

    trait :is_recommended_du do
      is_recommended_du { true }
    end
  end
end
