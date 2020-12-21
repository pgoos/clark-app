require './spec/support/features/page_objects/page_object'

class CockpitItems < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_cockpit = "/#{@locale}/app/manager"
  end


  def visit_page
    visit @path_to_cockpit
    Capybara.current_session.execute_script "window.localStorage.setItem('waitingtime_satisfaction', false);"
    # allow for the skeleton view
    page.assert_selector(".capybara-contracts-list")
  end

  def click_opportunity
    find(".capybara-opportunity-card").click
  end

  def expect_correct_page(opportunityId)
    # TODO: page.assert_selector('.offers__offer__option__type__tip')
    page.assert_current_path("/#{locale}/app/offer/#{opportunityId}")
  end

  def navigate_click(classname, location)
    find(classname).click
    page.assert_current_path("/#{locale}/app/#{location}")
  end
end
