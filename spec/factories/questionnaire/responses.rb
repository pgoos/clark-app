# frozen_string_literal: true

# == Schema Information
#
# Table name: questionnaire_responses
#
#  id               :integer          not null, primary key
#  response_id      :string
#  questionnaire_id :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  mandate_id       :integer
#  finished_at      :datetime
#  state            :string           default("created")
#

FactoryBot.define do
  factory :questionnaire_response, class: "Questionnaire::Response" do
    sequence(:response_id) { |n| "1234#{n}" }
    mandate factory: :mandate
    questionnaire

    trait :retirementcheck do
      association :questionnaire, factory: [:retirementcheck]
    end

    trait :completed do
      state { :completed }
    end

    trait :in_progress do
      state { :in_progress }
    end

    trait :analyzed do
      state { :analyzed }
    end
  end
end
