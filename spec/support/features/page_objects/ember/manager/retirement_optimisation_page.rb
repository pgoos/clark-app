require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class RetirementOptimisationPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_cockpit = "/#{locale}/app/manager/recommendations"
    @emberHelper = EmberHelper.new
  end

  def visit_page
    visit @path_to_cockpit
    reset_storage
    page.assert_current_path(@path_to_cockpit)
  end

  def expect_no_skeleton
    page.assert_selector(".manager__optimisations__wrapper--loaded", wait: 60)
  end

  def expect_on_optimisation_page
    page.assert_current_path(@path_to_cockpit)
  end

  def reset_storage
    Capybara.current_session.execute_script "window.localStorage.setItem('retirement-journey-start', '')"
  end

  def set_started_journey_in(amount_of_days)
    date = amount_of_days.to_i.days.ago.iso8601
    Capybara.current_session.execute_script "window.localStorage.setItem('retirement-journey-start', JSON.stringify('#{date}'))"
  end

  def shows_journey_card
    page.assert_selector('.retirement-empty-states__start-journey')
  end

  def click_start_journey
    find('.retirement-empty-states__start-journey__cta').click
  end

  def expect_on_gav_page
    page.assert_current_path("/#{locale}/app/manager/retirements/gav")
  end

  def expect_in_progress_with_day_percentage(percentage)
    elem = page.find('.ember-progress-bar__bar')
    search_string = "width: #{percentage.to_s}%"
    expect(elem[:style]).to include(search_string)
  end

  def expect_no_start_journey
    expect(page).not_to have_selector('.retirement-empty-states__start-journey')
  end

  def expect_no_in_progress
    expect(page).not_to have_selector('.retirement-empty-states__in-progress')
  end


  def expect_correct_text
    text = find('.retirement-calculator__card__title')
    expect(text).to have_content("Wie viel möchtest du monatlich zusätzlich für deine Rente sparen?")
  end

  def expect_orange_ring
    page.assert_selector('.progress-ring__end--adjustable')
  end

  def expect_slider_min_amount
    slider_min_amount = find('.retirement-calculator__card__saving__value')
    expect(slider_min_amount).to have_content("50")
  end

  def expect_appointment_cta
    page.assert_selector('.retirement-calculator__cta')
  end

  def expect_calcuator
    page.assert_selector('.retirement-calculator')
  end

  def click_make_appointment
    page.find('.retirement-calculator__cta').click
  end

  def expect_on_appointment_page
    page.assert_current_path("/#{locale}/app/appointment/form?hideBackButton=true&type=phone")
  end

  def has_gav_product
    gav_recommendation = page.find('.manager__contracts__cards-list__aspect manager__contracts__cards-list__aspect--retirement')
    expect(gav_recommendation).to have_content('Gesetzliche Krankenversicherung')
  end

  def expect_on_optimisation_page
    page.assert_current_path(@path_to_cockpit)
  end

  def expect_empty_retirement_state
    page.assert_selector(".retirement-done-icon")
  end

  def expect_no_calculator
    expect(page).not_to have_selector(".retirement-calculator")
  end

  def expect_no_request_salary_section
    expect(page).not_to have_selector(".retirement-empty-states__start-journey")
  end

end
