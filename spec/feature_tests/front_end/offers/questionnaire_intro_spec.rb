# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/questionnaire/questionnaire_intro_page"

RSpec.describe "Questionnaire Intro Page", :browser, :clark_context, type: :feature, js: true do
  let(:question_intro_page_obeject) { QuestionnaireIntroPage.new}
  let(:locale) { I18n.locale }

  context "visit the questionnaire" do

    let!(:user) do
      user = create(:user)
      user.update_attributes(mandate: create(:mandate))
      user.mandate.signature = create(:signature)
      user.mandate.confirmed_at = DateTime.current
      user.mandate.tos_accepted_at = DateTime.current
      user.mandate.info["wizard_steps"] = ["targeting", "profiling", "confirming"]
      user.mandate.save!
      user
    end

    let(:question) {
      q = create(:date_question)
      q.question_identifier="jq_1"
      q.save
      q
    }

    let(:question2) { create(:free_text_question) }

    let(:question3) {
      q2 = create(:multiple_choice_question_custom)
      q2.question_identifier="jq_3"
      q2.question_text="I am jump Question"
      q2.save
      q2
    }

    let!(:questionnaire) { create(:custom_questionnaire, identifier: "123456", questions: [question, question2, question3]) }

    before do
      login_as(user, scope: :user)
      question_intro_page_obeject.start_questionnaire(123456)
    end

    # TODO: JCLARK-60698
    pending "has the intro page with correct elements" do
      question_intro_page_obeject.page_has_welcome_message("Dein persönliches Angebot")
      question_intro_page_obeject.question_estimated_time_is("1")
      question_intro_page_obeject.number_of_questions_are("3")
      question_intro_page_obeject.has_cta_with_text("Fragebogen starten")
    end

  end

end
