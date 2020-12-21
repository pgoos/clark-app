require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class RequestOfferPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = "/#{locale}/app/select-category"
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_page
  end

  def expect_visible_category_count(count)
    page.assert_selector('.select_category__categories__category--item', count: count)
  end

  def expect_category_visible(category_id)
    page.assert_selector('li[data-id="' + category_id.to_s + '"]', visible: true)
  end

  def expect_divider(dividing_letter)
    page.assert_selector('.select_category__categories__category--divider', text: dividing_letter.to_s)
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

  def select_catagory_with_typeForm_questionnaire_and_click_next
    find('.select_category__categories li:nth-child(9)').click()
    find('.btn.btn-primary.btn--arrow.btn--arrow--right').click()
  end

  def select_catagory_with_custom_questionnaire_and_click_next
    find('.select_category__categories li:nth-child(2)').click()
    navigate_click('.btn.btn-primary.btn--arrow.btn--arrow--right', "questionnaire/ddWOBZ" )
  end

  def expect_to_navigate_to_typeform_questionnaire
    #sleep is necessary here since it takes time to load the type-form page
    sleep(2)
    expect(current_path).to include("to/tFH7n3")
  end
end
