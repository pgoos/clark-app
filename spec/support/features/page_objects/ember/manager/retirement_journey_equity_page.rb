require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class RetirementJourneyEquityPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_equity = "/#{locale}/app/manager/retirements/equity"
    @emberHelper = EmberHelper.new
  end

  def visit_page
    visit @path_to_equity
    page.assert_current_path(@path_to_equity)
  end

  def fill_in_input(value)
    field = find('.ember-text-field', visible: true)
    field.set(value)
  end

  def has_correct_elements
    page.assert_selector('.manager__retirement__journey-equity__title-section__header')
    expect(page).to have_content('Sonstige Altersvorsorge')
    expect(page).to have_content('Welches Vermögen steht dir aktuell zur Verfügung?')
    expect(page).to have_content('Bitte gebe dein Vermögen abzüglich aller Verbindlichkeiten wie etwa Krediten an')
    page.assert_selector('.manager__retirement__journey-equity__input__inner__text-field')
  end

  def expect_progress_bar_to_reflect_journey_step(step)
    percentage = (((step-1)/3.to_f) * 100).round
    progress_bar = page.find('.progress-bar__bar', visible: :all)
    search_string = "width: #{percentage.to_s}%"
    expect(progress_bar[:style]).to include(search_string)
  end

  def has_working_back_button
    page.find('.btn-back-split').click
    page.assert_current_path("/#{locale}/app/manager/retirements/pab")
  end

  def enter_amount
    page.assert_selector('.manager__retirement__journey-equity__input__inner__text-field')
    fill_in_input(10000)
  end

  def click_abbrechen_cta
    page.find('.btn-next-split').click
    page.assert_current_path("/#{locale}/app/manager/retirements/confirmation")
  end

end