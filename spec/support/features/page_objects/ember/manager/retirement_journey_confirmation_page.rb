require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class RetirementJourneyConfirmationPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_confirmation = "/#{locale}/app/manager/retirements/confirmation"
    @emberHelper = EmberHelper.new
  end

  def visit_page
    visit @path_to_confirmation
    page.assert_current_path(@path_to_confirmation)
  end

  def has_correct_elements
    expect(page).to have_content('Unsere Experten analysieren alle deine angegebenen Vorsorge Produkte. Das kann bis zu 5 Tage in Anspruch nehmen.')
    expect(page.find('.manager__retirement__wizard-confirmation__link')).to have_content('Wie machen wir das?')
  end

  def expect_progress_bar_to_reflect_journey_step(step)
    percentage = (((step-1)/3.to_f) * 100).round()
    progress_bar = page.find('.progress-bar__bar', visible: :all)
    search_string = "width: #{percentage.to_s}%"
    expect(progress_bar[:style]).to include(search_string)
  end

  def opens_pdf_on_cta_click
    expect(page.windows.size).to eq(1)
    page.find('.manager__retirement__wizard-confirmation__link').click
    # check that pdf has opened in a new window
    expect(page.windows.size).to eq(2)
  end

  def return_to_cockpit_with_cta
    page.find('.manager__retirement__wizard-confirmation__btn').click
    page.assert_current_path("/#{locale}/app/manager/recommendations")
  end

end