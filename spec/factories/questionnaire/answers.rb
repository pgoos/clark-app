# frozen_string_literal: true

# == Schema Information
#
# Table name: questionnaire_answers
#
#  id                        :integer          not null, primary key
#  questionnaire_question_id :integer
#  question_text             :string
#  answer                    :jsonb
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  questionnaire_response_id :integer
#

FactoryBot.define do
  factory :questionnaire_answer, class: 'Questionnaire::Answer' do
    question factory: :questionnaire_question
    question_text { 'Wie wohnst du?' }
    answer { { text: "In einem Haus" } }
    questionnaire_response factory: :questionnaire_response
  end
end
