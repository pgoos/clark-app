require './spec/support/features/page_objects/page_object'

class MandateFinishedPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @path_to_finished_page = "/#{locale}/app/mandate/finished"
  end

  def visit_finished
    visit @path_to_finished_page
    assert_current_path(@path_to_finished_page)
  end

  def expect_finished_page
    assert_current_path(@path_to_finished_page)
    expect(find(".mandate-finished__title").text).to include("Herzlich Willkommen")
  end

  def click_cta
    find('.btn-primary').click
  end

  def navigate_click(classname, location)
    btn = find(classname)
    btn.click
    assert_current_path("/#{locale}/app/#{location}")
  end
end
