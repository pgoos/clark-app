require "rails_helper"
require "./spec/support/features/page_objects/ember/questionnaire/questionnaire_page_object"
require "./spec/support/features/page_objects/ember/offer/offer_details_page_object"

# TECH DEBT to unskip it
# https://clarkteam.atlassian.net/browse/JCLARK-38201
RSpec.describe "Questionnaire Specs", :browser, type: :feature, js: true, skip: true do
  #TODO: replace repeated calls of questionnaire_page with questionnaire_page in all tests
  let!(:questionnaire_page) { QuestionnairePageObject.new }
  let!(:offer_view_page) { OfferDetailsPageObject.new }
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


  before  do
    I18n.locale = :de
  end



  context "general page structure and elements" do
    # describe "general page structure and elements" do
    before do
      login_as(user, scope: :user)
    end
    # THE TESTS ARE STILL FAILING, THERE IS AN ISSUE ALREADY TO MAKE THEM WORK IN JIRA-> JCLARK-8379

    # context "Testing for the answer service" do
    #
    #   let(:question) {
    #     q = create(:multiple_choice_question_custom)
    #     q.metadata["multiple-choice"]["multiple"] = true
    #     q.save
    #     q
    #   }
    #   let(:question2) {
    #     q2 = create(:free_text_question)
    #     q2.required = true
    #     q2.save
    #     q2
    #   }
    #   let(:question3) { create(:multiple_choice_question_custom) }
    #   let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question3, question, question2]) }
    #
    #   before do
    #     questionnaire_page.navigate("007")
    #   end
    #
    #   it "Given I am at Questionnaire introduction page, it should have introduction text and a button to start questions" do
    #     questionnaire_page.assert_quesionnaire_intro_page_has_a_heading_and_start_button
    #     debugger
    #   end
    # end

    #TEST PASSING
    context "The Questionnaire introduction page" do
      let(:question) {
        q = create(:multiple_choice_question_custom)
        q.metadata["multiple-choice"]["multiple"] = true
        q.save
        q
      }
      let(:question2) { create(:custom_question) }
      let(:question3) { create(:multiple_choice_question_custom) }
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question3, question]) }

      before do
        questionnaire_page.visit_by_id("007")
      end

      it "Given I am at Questionnaire introduction page, it should have introduction text and a button to start questions" do
        questionnaire_page.assert_quesionnaire_intro_page_has_a_heading_and_start_button
      end

    end

    #TEST PASSING
    # Start ---- Requires fake object getQuestionnaireWithSingleChoiceQuestionNotRequired
    # Test for Questionnnaire introduction page
    # AND
    # Tests for the single select questions not mandatory and with a preselected value
    context "The Questionnaire has a Single Choice question that is not mandatory" do
      let(:question) {
        q = create(:multiple_choice_question_custom)
        q.metadata["multiple-choice"]["choices"][0]["selected"] = true
        q.save
        q
      }
      let(:question2) { create(:free_text_question) }
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question, question2]) }

      before do
        questionnaire_page.visit_by_id("007")
      end

      # TODO: Have to delete the tests for the questionniare intro page from here
      it "Given I am at Questionnaire introduction page, it should have introduction text and a button to start questions" do
        questionnaire_page.assert_quesionnaire_intro_page_has_a_heading_and_start_button
      end

      it "Given I am at Questionnaire introduction page, On click of the Start Questionnaire button, first question should be displayed" do
        questionnaire_page.assert_quesionnaire_intro_page_has_a_heading_and_start_button
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
      end

      it "Given I move to next question, the previous question button should be visible" do
        questionnaire_page.assert_quesionnaire_intro_page_has_a_heading_and_start_button
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.assert_If_move_to_second_question_the_previous_button_should_be_visible
      end

      it "Given the question type is Single select question not mandatory, radio buttons with the options should be displayed along with preselected choice and the Next Question Button enabled" do
        # find(".question__navigation-button").click # before since it browses to a new route
        questionnaire_page.assert_quesionnaire_intro_page_has_a_heading_and_start_button
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.assert_headline_present("What sort of music do you enjoy?")
        questionnaire_page.assert_description_present("You can select the genere of music which you enjoy the most")
        questionnaire_page.assert_answer_options_with_radion_button_present
        questionnaire_page.assert_pre_selected_option
        questionnaire_page.assert_next_question_button_is_disabled(false)
      end
    end
    # End ---- Requires fake object getQuestionnaireWithSingleChoiceQuestionNotRequired


    #TEST PASSING
    # Start ---- Requires fake object getQuestionnaireWithSingleChoiceQuestionRequired
    # Tests for the single select questions  mandatory and without a preselected value
    context "The Questionnaire has a Single Choice question that is mandatory" do
      let(:question) {
        q = create(:multiple_choice_question_custom)
        q.required = true
        q.save
        q
      }
      let(:question2) { create(:free_text_question) }
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question, question2]) }

      before do
        questionnaire_page.visit_by_id("007")
      end
      it "Given the question type is Single select question mandatory, radio buttons with the options should be displayed with no preselected choice and the Next Question Button disabled" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.assert_headline_present("What sort of music do you enjoy?")
        questionnaire_page.assert_description_present("You can select the genere of music which you enjoy the most")
        questionnaire_page.assert_answer_options_with_radion_button_present
        questionnaire_page.assert_next_question_button_is_disabled(true)
      end

      it "Given the question type is Single select question mandatory, on Selection of an option, Next Button should be enabled" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.select_an_option
        questionnaire_page.assert_next_question_button_is_disabled(false)
        questionnaire_page.has_finish_questionnaire_cta
      end

      it "Given the question type is Single select question mandatory, I select an option and go to next question, once I return the selected option should be preselected" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.select_an_option
        # questionnaire_page.assert_If_move_to_second_question_the_previous_button_should_be_visible
        questionnaire_page.click_previous_button
        questionnaire_page.assert_previously_selected_option
      end
    end
    # END ---- Requires fake object getQuestionnaireWithSingleChoiceQuestionRequired

    ##############NOTE##############
    #
    #Have to include the functionality of preselected values for type freeText
    #
    ###############################

    #TEST PASSING
    # Start ---- Requires fake object getQuestionnaireWithFreeTextQuestionNotRequired
    # Tests for the freeText questions  not mandatory and without a preselected value
    context "The Questionnaire has a Free Text question that is not mandatory" do
      let(:question) { create(:free_text_question) }
      let(:question2) { create(:multiple_choice_question_custom) }
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question, question2]) }

      before do
        questionnaire_page.visit_by_id(questionnaire.identifier)
      end
      it "Given the question type is Free Text question not mandatory, Pre-filledd answer should be visible and the Next Question Button enabled" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.assert_headline_present("Do you wanna say something to #{I18n.t('.title')}?")
        questionnaire_page.assert_description_present("If you have any suggestions or feedback, now is the perfect opportunity")
        questionnaire_page.assert_next_question_button_is_disabled(false)
        questionnaire_page.assert_text_field_for_answer_is_present
        # questionnaire_page.asser_text_field_has_pre_filled_value("Clark is Awesome dude!")
      end

      it "Given the question type is Free Text question not mandatory, User type an answer goes to next question, If he comes back to the question the answer should be pre filled" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.set_an_answer_in_text_area("what is clark really")
        questionnaire_page.assert_If_move_to_second_question_the_previous_button_should_be_visible
        questionnaire_page.click_previous_button
        sleep 2
        questionnaire_page.asser_text_field_has_pre_filled_value("what is clark really")
      end
    end
    # END ---- Requires fake object getQuestionnaireWithFreeTextQuestionNotRequired


    #TEST PASSING
    # Start ---- Requires fake object getQuestionnaireWithFreeTextQuestionRequired
    # Tests for the freeText questions  mandatory and without a preselected value
    context "The Questionnaire has a Free Text question that is mandatory" do

      let(:question) {
        q = create(:free_text_question)
        q.required = true
        q.save
        q
      }

      let(:question2) {
        q = create(:free_text_question)
        q.save
        q
      }
      # let(:question2) { create(:multiple_choice_question_custom) }
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question, question2]) }
      before do
        questionnaire_page.visit_by_id("007")
      end
      it "Given the question type is Free Text question mandatory, No prefilled answer and the Next Question Button disabled" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.assert_headline_present("Do you wanna say something to #{I18n.t('.title')}?")
        questionnaire_page.assert_description_present("If you have any suggestions or feedback, now is the perfect opportunity")
        questionnaire_page.assert_next_question_button_is_disabled(true)
        questionnaire_page.assert_text_field_for_answer_is_present
        questionnaire_page.asser_text_field_has_pre_filled_value("")
      end

      it "Given the question type is Free Text question mandatory, User type an answer, next question button is enabled" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.set_an_answer_in_text_area("what is clark really")
        questionnaire_page.assert_next_question_button_is_disabled(false)
      end
    end
    # END ---- Requires fake object getQuestionnaireWithFreeTextQuestionRequired


    #TEST PASSING
    # Start ---- Requires fake object getQuestionnaireWithMultiCHoiceQuestionNotRequired
    # Tests for the multi select questions not mandatory and with a preselected value
    context "The Questionnaire has a Multiple Choice question that is not mandatory" do

      let(:question) {
        q = create(:multiple_choice_question_custom)
        q.metadata["multiple-choice"]["multiple"] = true
        q.metadata["multiple-choice"]["choices"][0]["selected"] = true
        q.metadata["multiple-choice"]["choices"][2]["selected"] = true
        q.save
        q
      }
      let(:question2) { create(:free_text_question) }
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question, question2]) }


      before do
        questionnaire_page.visit_by_id("007")
      end
      it "Given the question type is Multi select not mandatory, Preselected items should be checked and the Next Question Button enabled" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.assert_headline_present("What sort of music do you enjoy?")
        questionnaire_page.assert_description_present("You can select the genere of music which you enjoy the most")
        questionnaire_page.assert_answer_options_with_radion_button_present
        questionnaire_page.assert_next_question_button_is_disabled(false)
        questionnaire_page.asser_preselected_options_should_be_checked
      end

      it "Given the questrion type is Multi select question mandatory, I select some options and go to next question, once I return the selected option should be preselected" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.select_multiple_options
        questionnaire_page.assert_If_move_to_second_question_the_previous_button_should_be_visible
        questionnaire_page.click_previous_button
        questionnaire_page.assert_previously_selected_options_should_be_checked
      end
    end
    # End ---- Requires fake object getQuestionnaireWithMultiCHoiceQuestionNotRequired


    #TEST PASSING
    # Start ---- Requires fake object getQuestionnaireWithMultiCHoiceQuestionRequired
    # Tests for the multi select questions not mandatory and without a preselected value
    context "The Questionnaire has a Multiple Choice question that is  mandatory" do

      let(:question) {
        q = create(:multiple_choice_question_custom)
        q.metadata["multiple-choice"]["multiple"] = true
        q.required=true
        q.save
        q
      }

      let(:question2) { create(:free_text_question) }
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question, question2]) }

      before do
        questionnaire_page.visit_by_id("007")
      end
      it "Given the question type is Multi selec mandatory, No preselected items and the Next Question Button disabled" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.assert_headline_present("What sort of music do you enjoy?")
        questionnaire_page.assert_description_present("You can select the genere of music which you enjoy the most")
        questionnaire_page.assert_answer_options_with_radion_button_present
        questionnaire_page.assert_next_question_button_is_disabled(true)
      end

      it "Given the question type is Multi select question mandatory, User selects some options and the next button is enabled, i go to next question come back and the preselected options are checked" do
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.select_multiple_options
        questionnaire_page.assert_next_question_button_is_disabled(false)
        questionnaire_page.assert_If_move_to_second_question_the_previous_button_should_be_visible
        questionnaire_page.click_previous_button
        questionnaire_page.assert_previously_selected_options_should_be_checked
      end
    end
    # End ---- Requires fake object getQuestionnaireWithMultiCHoiceQuestionRequired


    #TEST PASSING
    # Start ---- Requires fake object getQuestionnaireWithMultiCHoiceQuestionRequired
    # Tests for jump logic
    context "The Questionnaire has a Multiple Choice question that is  mandatory" do
      let(:question) {
        q = create(:multiple_choice_jump_question_custom)
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
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "007", questions: [question, question2, question3]) }

      before do
        questionnaire_page.visit_by_id("007")
      end

      it "Given the question type is Multi selec mandatory, No preselected items and the Next Question Button disabled" do

        questionnaire_page.assert_quesionnaire_intro_page_has_a_heading_and_start_button
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.assert_headline_present("What sort of music do you enjoy?")
        questionnaire_page.assert_description_present("You can select the genere of music which you enjoy the most")
        questionnaire_page.assert_answer_options_for_jump_question_present
        questionnaire_page.select_jump_option
        questionnaire_page.click_next_button
        questionnaire_page.assert_headline_present("I am jump Question")
      end
    end
    # End ---- Requires fake object getQuestionnaireWithMultiCHoiceQuestionRequired

    context "Given that the Questionnaire creates an automated offer" do
      before(:each) { login_as user, :scope => :user }
      let!(:category) { create(:category) }
      let(:question) {
        q = create(:multiple_choice_question)
        q.question_identifier="jq_1"
        q.save
        q
      }
      random_questionnaire_indentifier = "007"
      let!(:questionnaire) { create(:custom_questionnaire, identifier: random_questionnaire_indentifier, category: category, questions: [question]) }

      let!(:q_response) { create(:questionnaire_response, questionnaire: questionnaire, mandate: user.mandate) }
      subject{ json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/finish" }

      let!(:offer) { create(:offer, state: "active", mandate: user.mandate) }
      let!(:existing_opportunity) { create :opportunity, mandate: user.mandate, category: category, offer_id: offer.id }

      it "should display the questionnaire and redirect to offer view after user finishes the last question" do
        questionnaire_page.visit_by_id(random_questionnaire_indentifier)
        questionnaire_page.click_start_questionnaire
        questionnaire_page.answer_question_and_click_finish
        # Needed for page transition
        sleep 2
        offer_view_page.see_offer_by_id(offer.id)
      end
    end

    #Test for the high margin questionnaire appointment
    context "The Questionnaire is high margin" do
      let(:question) {
        q = create(:multiple_choice_jump_question_custom)
        q.question_identifier = "jq_1"
        q.save
        q
      }

      let(:question2) { create(:free_text_question) }
      let(:question3) {
        q2 = create(:multiple_choice_question_custom)
        q2.question_identifier="jq_3"
        q2.question_text="I am jump Question"
        q2.save
        q2.required = false
        q2
      }
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "Q2BS6v", questions: [question]) }

      before do
        questionnaire_page.visit_by_id("Q2BS6v")
      end

      it "should show the appointment form as the last question" do
        questionnaire_page.assert_quesionnaire_intro_page_has_a_heading_and_start_button
        questionnaire_page.assert_click_start_questionnaire_button_and_first_question_should_be_displayed
        questionnaire_page.select_jump_option
        # Needed to add sleep for the page transitition
        sleep 2
        questionnaire_page.assert_headline_present("Noch ein Schritt, um dein persönliches Angebot zu erhalten")
        questionnaire_page.assert_description_present("Bitte wähle einen verbindlichen Termin für ein Beratungsgespräch mit einem #{I18n.t('.title')}-Experten.")
        #   have to extend this test once the general (*salute*) problem for the questionnaire is resolved
      end
    end
  end
end
