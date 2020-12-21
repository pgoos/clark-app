# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"

class DemandCheckPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale = locale
    @path_to_pre_demandcheck = "/#{locale}/app/demandcheck/intro"
    @path_to_demandcheck = "/#{locale}/app/demandcheck"
    @path_to_demandcheck_done = "/#{locale}/app/demandcheck/finished"
    @path_to_recommendations = "/#{locale}/app/manager/recommendations"
  end

  def visit_page
    visit @path_to_demandcheck
  end

  def visit_pre_demandchck
    visit @path_to_pre_demandcheck
    page.assert_current_path(@path_to_pre_demandcheck)
  end

  def assert_recommendations_page
    page.assert_current_path(@path_to_recommendations)
  end

  def correct_elements
    page.assert_selector(".capybara-demandcheck-questionnaire-main")
    page.assert_selector(".capybara-demandcheck-question-section")
    page.assert_selector(".capybara-demandcheck-question-hint")
    page.assert_selector(".capybara-demandcheck-question")
    page.assert_selector(".capybara-demandcheck-answer")
    page.assert_selector(".capybara-demandcheck-ctas")
    page.assert_selector(".progress-bar")
  end

  def click_list_item(index)
    page.assert_selector(".capybara-demandcheck-list-item")
    page.all(".capybara-demandcheck-list-item")[index - 1].click
  end

  def select_answer_with_text(text)
    page.find(".capybara-demandcheck-list-item", text: text).click
  end

  def select_checkbox_with_text(text)
    page.find(".demand-check__checkbox-section__text", text: text).click
  end

  def click_cta
    find(".capybara-demandcheck-primary-cta").click
  end

  def ensure_cta_enabled
    find(".capybara-demandcheck-primary-cta")[:disabled => false]
  end

  def ensure_cta_disabled
    find(".capybara-demandcheck-primary-cta")[:disabled => true]
  end

  def click_back_cta
    find(".capybara-demandcheck-secondary-cta").click
  end

  def scroll_top
    Capybara.current_session.execute_script("window.scrollTo(0, 0);")
  end

  def fill_in_input(value)
    field = find(".text-field-answer", visible: true)
    field.set(value)
  end

  def assert_demandcheck_done
    JsHelper.wait_for_ajax(page)
    page.assert_current_path(@path_to_demandcheck_done)
    page.assert_selector(".faux-analysing")
    page.assert_selector(".capybara-faux-image")
    page.assert_selector(".faux-analysing-text")
  end

  def assert_question(question)
    element = find(".capybara-demandcheck-question")
    element.assert_text(question)
  end

  def assert_hint(message)
    element = find(".capybara-demandcheck-question-")
    element.assert_text(message)
  end

  def navigate_click(classname, location)
    page.assert_selector(classname)
    find(classname).click
    page.assert_current_path("/#{locale}/app/#{location}")
  end

  def answer_demandcheck
    assert_question("Wo wohnst du?")
    scroll_top
    select_answer_with_text("In einer gemieteten Wohnung")

    assert_question("Planst du, in den nächsten 6 Monaten ein Haus zu bauen?")
    scroll_top
    select_answer_with_text("Nein")

    assert_question("Besitzt du eines der folgenden Fahrzeuge?")
    scroll_top
    select_checkbox_with_text("Auto")
    click_cta

    assert_question("Wie steht es um deine Familiensituation?")
    select_answer_with_text("Ich bin Single")

    sleep 30

    assert_question("Hast du Kinder?")
    select_answer_with_text("Ja")
    fill_in_input(2)
    ensure_cta_enabled
    click_back_cta

    assert_question("Wie steht es um deine Familiensituation?")
    click_cta

    assert_question("Hast du Kinder?")
    select_answer_with_text("Nein")
    ensure_cta_enabled
    click_cta

    assert_question("Was machst du beruflich?")
    scroll_top

    select_answer_with_text("Angestellter")
    click_cta

    assert_question("Was machst du in deiner Freizeit?")
    select_checkbox_with_text("Ich reise sehr viel")
    click_cta

    assert_question("Hast du Tiere?")
    select_checkbox_with_text("Hund")
    click_cta

    assert_question("Wie hoch ist dein aktuelles Jahresbruttogehalt?")
    fill_in_input(100_000)
    click_cta

    assert_demandcheck_done
    assert_recommendations_page
  end

  def answer_demandcheck_formal
    assert_question("Wo wohnen Sie?")
    scroll_top
    select_answer_with_text("In einer gemieteten Wohnung")

    assert_question("Planen Sie, in den nächsten 6 Monaten ein Haus zu bauen?")
    scroll_top
    select_answer_with_text("Nein")

    assert_question("Besitzen Sie eines der folgenden Fahrzeuge?")
    scroll_top
    select_checkbox_with_text("Auto")
    click_cta

    assert_question("Wie steht es um Ihre Familiensituation?")
    select_answer_with_text("Ich bin Single")

    assert_question("Haben Sie Kinder?")

    select_answer_with_text("Ja")
    ensure_cta_enabled
    fill_in_input(2)
    fill_in_input("")
    click_back_cta

    assert_question("Wie steht es um Ihre Familiensituation?")
    click_cta

    assert_question("Haben Sie Kinder?")
    select_answer_with_text("Nein")
    ensure_cta_enabled
    click_cta

    assert_question("Was machen Sie beruflich?")
    scroll_top

    select_answer_with_text("Angestellter")
    click_cta

    assert_question("Was machen Sie in Ihrer Freizeit?")

    select_checkbox_with_text("Ich reise sehr viel")
    click_cta

    assert_question("Haben Sie Tiere?")

    select_checkbox_with_text("Hund")
    click_cta

    assert_question("Wie hoch ist Ihr aktuelles Jahresbruttogehalt?")
    fill_in_input(100_000)
    click_cta

    assert_demandcheck_done
    assert_recommendations_page
  end
end
