# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/page_objects/ember/ember_helper"

class MandateRegisterPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @path_to_page = "/#{locale}/app/mandate/register"
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page(setPushEnabled)
    visit @path_to_page

    if setPushEnabled
      Capybara.current_session.execute_script "window.localStorage.setItem('pushEnabled', 'true');"
    end

    # Because of liquid fire animations
    sleep 2
  end

  def fill_password
    fill_in "mandate_register_password", with: Settings.seeds.default_password
  end

  def click_registration_finished
    find(".btn-primary").click
  end

  def navigate_click(classname, location)
    btn = find(classname)
    btn.click
    assert_current_path("/#{locale}/app/#{location}")
  end

  def shows_current_step(number)
    element = find(".mandate_process_number__amount")
    element.assert_text(number)
  end

  def expect_correct_elements
    page.assert_selector(".register-lead__process")
    page.assert_selector(".reveal_wrapper__eye")
    page.assert_selector("#mandate_register_email")
    page.assert_selector("#mandate_register_password")
    page.assert_selector(".btn-primary")
  end

  def expect_push(visible)
    page.assert_selector(".push-toggle", visible: visible)
  end

  def expect_toggle_off
    page.assert_no_selector(".push-toggle__controls__toggle--toggled")
  end

  def expect_toggle_on
    page.assert_selector(".push-toggle__controls__toggle--toggled")
  end

  def expect_settings_message(visible)
    page.assert_selector(".push-toggle__deselect", visible: visible)
  end

  def click_toggle
    find(".push-toggle__controls__toggle").click
  end

  def visit_register
    visit @path_to_page
  end

  def click_cta
    find(".btn-primary").click
  end
end
