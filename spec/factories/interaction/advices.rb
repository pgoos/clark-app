# frozen_string_literal: true

# == Schema Information
#
# Table name: interactions
#
#  id           :integer          not null, primary key
#  type         :string
#  mandate_id   :integer
#  admin_id     :integer
#  topic_id     :integer
#  topic_type   :string
#  direction    :string
#  content      :text
#  metadata     :jsonb
#  acknowledged :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :advice, class: "Interaction::Advice" do
    mandate
    admin
    direction    { "out" }
    content      { "Wir sollten deine Versicherung mal prüfen, du zahlst viel zu viel" }
    metadata     {}
    acknowledged { false }
    product

    trait :created_by_robo_advisor do
      after :build do |advice|
        advice.metadata ||= {}
        advice.metadata["created_by_robo_advisor"] = true
      end
    end

    trait :reoccurring_advice do
      after :build do |advice|
        advice.metadata ||= {}
        advice.metadata["created_by_robo_advisor"] = true
        advice.metadata["reoccurring_advice"] = true
      end
    end

    trait :valid do
      valid { true }
    end

    trait :invalid do
      valid { false }
    end

    trait :keeper do
      identifier { :keeper_switcher }
    end

    factory :manual_advice do
      content                 { Faker::Lorem.paragraph }
      cta_link                { Faker::Internet.url }
      identifier              { "keeper_switcher" }
      manual_classification   { "none" }
      created_by_robo_advisor { false }

      factory :manual_advice_keeper do
        manual_classification   { "keeper" }
      end

      factory :manual_advice_switcher do
        manual_classification   { "switcher" }
      end
    end

    trait :created_while_instant_advice_is_on do
      metadata { { hide_while_instant_advice_is_on: true } }
    end
  end
end
