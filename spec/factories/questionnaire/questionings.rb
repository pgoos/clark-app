# frozen_string_literal: true

# == Schema Information
#
# Table name: questionnaire_questionings
#
#  id                        :integer          not null, primary key
#  questionnaire_id          :integer
#  questionnaire_question_id :integer
#  sort_index                :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

FactoryBot.define do
  factory :questionnaire_questioning, class: 'Questionnaire::Questioning' do
    question factory: :questionnaire_question
    questionnaire factory: :questionnaire
  end
end

