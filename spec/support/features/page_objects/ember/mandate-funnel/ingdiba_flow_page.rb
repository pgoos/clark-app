require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class IngdibaFlowPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @path_to_page = "/#{locale}/app/mandate/status"
    @path_to_targeting = "/#{locale}/app/mandate/targeting"
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_page
  end

  def visit_cockpit_targeting
    visit @path_to_targeting
  end

  def expect_iban_page
    expect(current_path).to eq("/#{locale}/app/mandate/iban")
  end

  def visit_route(route)
    visit route
  end

  def click_cta
    find('.btn-primary').click
  end

  def navigate_click(classname, location)
    btn = find(classname)
    @emberHelper.ember_transition_click btn
    expect(current_path).to eq("/#{locale}/app/#{location}")
  end

  def expect_correct_elements
    page.assert_selector('.mandate-mam')
  end

  def ing_status_page_has_proper_elements
    page.assert_selector('.btn-ing')
  end

  def ing_preview_page_has_proper_elements
    page.assert_selector('.btn-ing')
  end

  def ing_targeting_has_proper_elements
    page.assert_selector('.btn-ing')
  end

  def ing_profiling_has_proper_elements
    page.assert_selector('.btn-ing')
  end
end
