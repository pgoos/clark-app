# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfferGeneration::RulesRepository, :integration do
  subject { OfferGeneration.rules_repository }

  it "should deliver the rules for matching answers" do
    quest_ident = "quest_ident1"

    # the factory creates a question with three answer options:
    question1 = create(:multiple_choice_question, question_identifier: "question1")
    question2 = create(:multiple_choice_question_multiple, question_identifier: "question2")
    question3 = create(:typeform_question, question_type: "text")
    questionnaire = create(:questionnaire, identifier: quest_ident, questions: [question1, question2])
    automation = create(:offer_automation, state: "inactive", questionnaire: questionnaire)

    question_reader1 = Domain::Questionnaires::Question.init(model: question1)
    question_reader2 = Domain::Questionnaires::Question.init(model: question2)

    # prepare the response:
    response = create(:questionnaire_response, questionnaire: questionnaire)

    answer1 = question_reader1.choices[1].value
    create(:questionnaire_answer, question: question1, questionnaire_response: response, answer: {text: answer1})

    question2_choices = question_reader2.choices[0..1].map(&:value)
    answer2 = question2_choices.join(", ")
    create(:questionnaire_answer, question: question2, questionnaire_response: response, answer: {text: answer2})

    # this answer should be ignored by the repository (not necessarily by the matrix)
    create(:questionnaire_answer, question: question3, questionnaire_response: response, answer: {text: "ignored"})

    expected_rule = nil

    # create nine active rules according to the combinations of the possible response values:
    question_reader1.choices.each do |choice|
      question_reader2.choices.each do |choice2|
        choice2_value = choice2.value == question2_choices.first ? question2_choices : [choice2.value]
        rule = create(
          :active_offer_rule,
          offer_automation: automation,
          answer_values: {
            question1.question_identifier => choice.value,
            question2.question_identifier => choice2_value
          }
        )
        next unless choice.value == answer1 && expected_rule.nil?

        expected_rule = rule

        # also create an inactive rule with the same answer values:
        create(
          :offer_rule,
          offer_automation: automation,
          answer_values: {
            question1.question_identifier => choice.value,
            question2.question_identifier => question2_choices
          }
        )
      end
    end

    raise "no expected rule assigned" if expected_rule.blank?

    expect(subject.find_active_rules_for(response: response, question_types: %(multiple-choice))).to be_empty

    automation.activate!
    expect(subject.find_active_rules_for(response: response, question_types: %(multiple-choice))).to eq([expected_rule])

    expected_rule.deactivate!
    expect(subject.find_active_rules_for(response: response, question_types: %(multiple-choice))).to be_empty
  end
end
