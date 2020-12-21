# frozen_string_literal: true

# == Schema Information
#
# Table name: questionnaires
#
#  id                 :integer          not null, primary key
#  identifier         :string
#  created_at         :datetime
#  updated_at         :datetime
#  category_id        :integer
#  questionnaire_type :string           default("typeform"), not null
#  name               :string
#  description        :text
#  internal_name      :string
#

FactoryBot.define do
  factory :questionnaire do
    sequence(:identifier, &:to_s)
    questionnaire_type { "typeform" }

    factory :custom_questionnaire do
      questionnaire_type { "typeform" }
      name { "Our own Questionnaire" }
      description { "Questionaire Description" }
    end

    factory :bedarfscheck_questionnaire do
      questionnaire_type { "custom" }
      name { "Our Bedarfscheck" }
      identifier { "bedarfscheck" }
      description { "Bedarfscheck Description" }
    end

    factory :ember_questionnaire do
      identifier { "ddWOBZ" }
    end

    factory :typeform_questionnaire do
      identifier { "tFH7n3" }
    end

    factory :retirementcheck do
      identifier { "retirementcheck" }
    end
  end
end
