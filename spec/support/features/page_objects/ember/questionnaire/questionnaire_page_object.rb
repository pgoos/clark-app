require "./spec/support/features/page_objects/page_object"

class QuestionnairePageObject < PageObject
  include FeatureHelpers

  def intialize(locale = I18n.locale)
    @locale = locale
  end

  def navigate(questionnaire_identifier)
    visit "/#{locale}/app/questionnaire/#{questionnaire_identifier}"
  end

  def visit_by_id(questionnaire_identifier)
    visit "/#{locale}/app/questionnaire/#{questionnaire_identifier}"
    assert_current_path("/#{locale}/app/questionnaire/#{questionnaire_identifier}")
  end

  def expect_consent_section
    page.assert_selector(".questionnaire__intro__consent")
  end

  def expect_no_consent_section
    expect(page).not_to have_selector(".questionnaire__intro__consent")
  end

  def click_consent_link
    find(".questionnaire__intro__consent__content__link").click
  end

  def expect_consent_modal
    page.assert_selector(".health-data-consent-modal")
  end

  def assert_quesionnaire_intro_page_has_a_heading_and_start_button
    page.assert_selector(".questionnaire__intro__middle-section__title")
    page.assert_selector(".btn-primary")
  end

  def assert_click_start_questionnaire_button_and_first_question_should_be_displayed
    page.assert_selector(".btn-primary")
    click_next_button
  end

  def click_start_questionnaire
    page.assert_selector('.questionnaire__intro__cta')
    find('.questionnaire__intro__cta').click
    page.assert_selector(".questionnaire__question__title")
  end

  def answer_question_and_click_finish
    page.assert_selector("li.questionnaire__answers__answer", minimum: 1)
    first("li.questionnaire__answers__answer").click
    sleep 1
    page.assert_selector(".btn-primary")
    find(".btn-primary").click
  end

  def assert_If_move_to_second_question_the_previous_button_should_be_visible
    page.assert_selector(".btn-primary")
    click_next_button
    page.assert_selector(".btn-secondary")
  end

  def assert_answer_options_with_radion_button_present
    page.assert_selector("li", text: "Alternative")
    page.assert_selector("li", text: "Blues")
    page.assert_selector("li", text: "Country")
    page.assert_selector("li", text: "Electronic")
    page.assert_selector("li", text: "Metal")
  end

  def assert_answer_options_for_jump_question_present
    page.assert_selector("li", text: "Yes")
    page.assert_selector("li", text: "No")
  end

  def assert_headline_present(headline)
    page.assert_text(/#{headline}/i)
  end

  def assert_description_present(description)
    page.assert_selector("#description", text: description)
  end

  def assert_pre_selected_option
    page.assert_selector("li", text: "Alternative")
  end

  def assert_next_question_button_is_disabled(isEnabled)
    page.assert_selector(".btn-primary", visible: isEnabled)
  end

  def select_jump_option
    page.find("li", text: "Yes").click
  end

  def select_an_option
    page.find("li", text: "Metal").click
  end

  def click_next_button
    page.assert_selector(".btn-primary")
    find(".btn-primary").click
  end

  def click_previous_button
    page.assert_selector(".btn-secondary")
    find(".btn-secondary").click
  end

  def assert_previously_selected_option
    page.assert_selector("li", text: "Metal")
  end

  def assert_text_field_for_answer_is_present
    page.assert_selector(".text-field-answer")
  end

  def asser_text_field_has_pre_filled_value(text)
    assert_text_field_for_answer_is_present
    expect(find(".text-field-answer").value).to eq(text)
  end

  def set_an_answer_in_text_area(text)
    find(".text-field-answer").set(text)
  end

  def asser_preselected_options_should_be_checked
    page.assert_selector("li", text: "Alternative")
    page.assert_selector("li", text: "Country")
  end

  def select_multiple_options
    page.find("li", text: "Metal").click
    page.find("li", text: "Blues").click
  end

  def assert_previously_selected_options_should_be_checked
    page.assert_selector("li", text: "Metal")
    page.assert_selector("li", text: "Blues")
  end

  def has_finish_questionnaire_cta
    page.assert_selector(".btn-primary", text: "Angebot anfordern")
  end


end
# -----------
# Page interactions
# -----------
