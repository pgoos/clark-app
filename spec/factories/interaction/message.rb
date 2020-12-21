# frozen_string_literal: true

FactoryBot.define do
  factory :interaction_message, class: 'Interaction::Message' do
    trait :with_mandate do
      mandate
    end
  end
end
