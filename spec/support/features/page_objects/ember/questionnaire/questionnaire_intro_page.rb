require './spec/support/features/page_objects/page_object'

class QuestionnaireIntroPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
  end

  def start_questionnaire(questionnaire_identifier)
    visit "/#{locale}/app/questionnaire/#{questionnaire_identifier}"
    assert_current_path("/#{locale}/app/questionnaire/#{questionnaire_identifier}")
  end

  def page_has_welcome_message(text)
    expect(find('.questionnaire__intro__middle-section__title').text).to  eq(text)
  end

  def question_estimated_time_is(minutes)
    expect(find('.questionnaire__intro__middle-section__stats__count__value').text).to eq(minutes)
  end

  def number_of_questions_are(number_of_questions)
    expect(find('.questionnaire__intro__middle-section__stats__time__value').text).to eq(number_of_questions)
  end

  def has_cta_with_text(text)
    find_button(text)
  end
end
