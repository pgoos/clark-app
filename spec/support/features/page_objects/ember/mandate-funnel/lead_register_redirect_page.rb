require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/page_objects/ember/ember_helper"

class LeadToRegisterPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @path_to_page = "/#{locale}/app/manager"
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_page
    # Sleep is for the redirect
    sleep 2
  end

  def expect_on_register
    expect(current_path).to eq("/#{locale}/app/mandate/register")
  end

  def expect_complete_registration_prompt
    page.assert_selector(".manager__optimisations-empty")
  end

  def expect_on_cockpit
    expect(current_path).to eq("/#{locale}/app/manager")
  end

  def navigate_click(classname, location)
    btn = find(classname)
    @emberHelper.ember_transition_click btn
    expect(current_path).to eq("/#{locale}/app/#{location}")
  end

  def expect_correct_elements
    page.assert_selector(".mandate-mam")
  end
end
