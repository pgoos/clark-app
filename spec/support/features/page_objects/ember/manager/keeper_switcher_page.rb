require "./spec/support/features/page_objects/page_object"

class KeeperSwitcherPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_cockpit = "/#{@locale}/app/manager"
  end

  # ----------------
  # Page interactions
  #-----------------

  # Helpers for all of the iban / notifications on the contracts page
  def visit_page
    visit @path_to_cockpit
    Capybara.current_session.execute_script "window.sessionStorage.setItem('clark-spash-screen', 'false');"
    Capybara.current_session.execute_script "window.localStorage.setItem('manager', '{}');"
    Capybara.current_session.execute_script "window.localStorage.setItem('reminders-since-mandate', 3);"
    # allow for the skeleton view
    page.assert_selector(".capybara-contracts-list")
  end

  def expect_no_switcher_message(productID)
    page.assert_no_selector('.manager__products-list__product[data-id="'+productID.to_s+'"] .manager__products-list__product__notification-row__status__text')
  end

  def expect_switcher_unknown_message(productID)
    expect(find('.manager__products-list__product[data-id="'+productID.to_s+'"] .manager__products-list__product__notification-row__status__text').text).to eq("#{I18n.t('manager.products.savings_state.unknown')}")
  end

  def expect_switcher_leistung_message(productID)
    expect(find('.manager__products-list__product[data-id="'+productID.to_s+'"] .manager__products-list__product__notification-row__status__text').text).to eq("#{I18n.t('manager.products.savings_state.leistung')}")
  end

  def expect_switcher_sparen_message(productID)
    expect(find('.manager__products-list__product[data-id="'+productID.to_s+'"] .manager__products-list__product__notification-row__status__text').text).to eq("#{I18n.t('manager.products.savings_state.sparen')}")
  end

  def expect_switcher_default_message(productID)
    expect(find('.manager__products-list__product[data-id="'+productID.to_s+'"] .manager__products-list__product__notification-row__status__text').text).to eq("#{I18n.t('manager.products.savings_state.default')}")
  end


  # Clicking on an item with x class should take us to y page
  def navigate_click(classname, location)
    page.assert_selector(classname)
    find(classname).click
    page.assert_current_path("/#{locale}/app/#{location}")
  end
end
