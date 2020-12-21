require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class ContractsCockpit < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = "/#{@locale}/app/manager"
  end

  def visit_page
    visit @path_to_page
    page.assert_current_path("/#{@locale}/app/manager")
  end

  def expect_skeleton_gone
    page.assert_selector(".capybara-contracts-list", wait: 60)
  end

  def click_start_bedarfscheck
    page.assert_selector('.capybara-do-demandcheck')
    navigate_click('.capybara-do-demandcheck', 'demandcheck/intro')
  end

  def go_to_optimization
    # go to optimization tab
  end

  def see_product(category_name)
    find('.capybara-card', :text => "#{category_name}")
  end

  def see_product_with_product(product)
    find(".capybara-standard-product-card#{product.id}")
  end

  def see_inquiry(inquiry)
    find(".capybara-inquiry-card#{inquiry.id}")
  end

  def click_start_demandcheck
    find('.capybara-do-demandcheck').click
  end

  def close_modal
    find('.ember-modal__body__close').click
  end

  def navigate_click(classname, location)
    find(classname).click
    page.assert_current_path("/#{@locale}/app/#{location}")
  end

  def expect_no_retirement_card_status
    find('.capybara-gav-card').assert_no_text('bis Details verfügbar')
    find('.capybara-equity-card').assert_no_text('In Bearbeitung')
  end

end
