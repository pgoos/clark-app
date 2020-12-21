require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class WiatingTimeMessangingPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @mandate_finsihed_path = "/#{locale}/app/mandate/finished"
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------
  def visit_mandate_finsihed_page
    visit @mandate_finsihed_path
  end

  def set_decided_on_inq_waiting
    Capybara.current_session.execute_script "window.localStorage.setItem('will_wait_for_inquiry', true);"
    page.driver.browser.navigate.refresh
  end

  def reset_decided_on_inq_waiting
    Capybara.current_session.execute_script "window.localStorage.setItem('will_wait_for_inquiry', false);"
    page.driver.browser.navigate.refresh
  end

  def expect_standard_finished_page
    sleep 3
    expect(page).not_to have_selector('.mandate-finished')
  end

  def expect_varaiant_finished_page
    sleep 3
    page.assert_selector('.mandate-finished')
  end

  # Clicking on an item with x class should take us to y page
  def navigate_click(classname, location)
    btn = find(classname)
    @emberHelper.ember_transition_click btn
    expect(current_path).to eq("/#{locale}/app/#{location}")
  end

  def navigate_to(location)
    @emberHelper.set_up_ember_transition_hook
    visit "/#{locale}/app/#{location}"
    @emberHelper.wait_for_ember_transition
  end
end
