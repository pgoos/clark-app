require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class SelectCategoryPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = "/#{locale}/app/mandate/targeting/selection" # /selection suffix for targeting experiment
    @path_to_manager = "/#{locale}/app/manager"
    @path_to_simple_page = "/#{locale}/app/iban"
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_page
    page.assert_selector('.manager__cat-select__categories__category--regular', minimum: 2, wait: 20)
  end

  def click_item(id)
    page.assert_selector('.manager__cat-select__categories__category--regular[data-id="' + id.to_s + '"]')
    find('.manager__cat-select__categories__category--regular[data-id="' + id.to_s + '"]').click
  end

  def click_popular(id)
    find('.manager__cat-select__categories__category--popular[data-id="' + id.to_s + '"]').click
  end

  def select_category_item(category)
    find('.select_category__categories__category[data-id="' + category.id.to_s + '"]').click
  end

  def select_category(category)
    find('.manager__cat-select__categories__category--regular[data-id="' + category.id.to_s + '"]').click
  end

  def select_category_id(id)
    find('.manager__cat-select__categories__category--item[data-id="'+id.to_s+'"]').click
  end

  def click_item_fast(id)
    find('.manager__cat-select__categories__category--regular[data-id="' + id.to_s + '"]').click
  end

  def click_selected_item(id)
    find('.manager__cat-select__categories--selected li[data-id="' + id.to_s + '"] .manager__cat-select__categories__category__inner').click
  end

  def search_for(query)
    fill_in 'search_input', with: query
  end

  def shows_item(id)
    page.assert_selector('li[data-id="' + id.to_s + '"]', visible: true)
  end

  def deselect(id)
    find('.manager__cat-select__categories--selected li[data-id="' + id.to_s + '"] ').click
  end

  def select_unknown
    find('.manager__cat-select__categories__category--unknown').click
  end

  def expect_targeting_page
    page.assert_selector('.wizard-select-insurance__process')
    page.assert_selector(".cucumber-targeting-insurance-intro")
    page.assert_selector('.wizard-select-insurance__search-section__inner')
    page.assert_selector('.manager__cat-select__categories__category--item')
  end

  def expect_steps_number(step)
    expect(find('.mandate_process_number').text).to eq("1 /"+step.to_s)
  end

  def expect_no_steps
    expect(page).not.to have_selector('mandate_process_number__amount')
  end

  def expect_no_cta
    page.assert_selector('.btn-primary', visible: false)
  end

  def expect_cta
    page.assert_selector('.btn-primary', visible: true)
  end

  def expect_selected(categoryIds)
    categoryIds.each do |id|
      page.assert_selector('.manager__cat-select__categories--selected li[data-id="' + id.to_s + '"]', count: 1)
    end
  end

  def expect_heath_modal
    page.assert_selector('.add-category-health-modal', visible: true)
  end

  def expect_phv_modal
    page.assert_selector('.add-category-phv-modal', visible: true)
  end

  def expect_hr_modal
    page.assert_selector('.add-category-hr-modal', visible: true)
  end

  def expect_mandate_targeting_page
    page.assert_selector('.manager__cat-select__categories__category--item')
  end

  def click_submit
    page.find('.btn-primary').click
  end

  def click_item_with_class(className)
    find(".#{className}").click
  end

  def navigate_click(classname, location)
    btn = find(classname)
    @emberHelper.ember_transition_click btn
    expect(current_path).to eq("/#{locale}/app/#{location}")
  end
end
