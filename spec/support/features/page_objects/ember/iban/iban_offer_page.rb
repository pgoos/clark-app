require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class IbanOfferPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------

  def navigate offer_id
    visit "/#{locale}/app/offer/#{offer_id}/iban"
  end

  # Clicking on an item with x class should take us to y page
  def navigate_click(classname, location)
    btn = find(classname)
    @emberHelper.ember_transition_click btn
    expect(current_path).to eq("/#{locale}/app/#{location}")
  end

  def navigate_checkout(offer_id, option_id)
    visit "/#{locale}/app/offer/#{offer_id}/checkout/#{option_id}"
  end

  def wait_for_page
    @emberHelper.wait_for_ember_transition
  end

  def set_up_wait_hook
    @emberHelper.set_up_ember_transition_hook
  end

  def clear_form
    fill_in 'iban', with: ''
  end

  def fill_in_iban iban_number
    fill_in 'iban', with: iban_number
  end

  def submit_form
    # Capybara.current_session.execute_script "$('.btn-primary').attr('disabled', false)"
    btn = find('.btn-primary')
    @emberHelper.ember_transition_click btn
  end

  def expect_offer_confirmation
    expect(current_path).to eq("/#{locale}/app/offer/confirmation")
  end

  def expect_iban_error
    page.assert_selector('.ig__error-msg')
  end

  def expect_manager_page
    expect(current_path).to eq("/#{locale}/app/manager")
  end

  def expect_login_page
    expect(current_path).to eq("/#{locale}/login")
  end

  def shows_correct_page_elements
    page.assert_selector('.iban-offer-form__header__title')
    page.assert_selector('.iban-offer-form__header')
    page.assert_selector('.offer-checkout__details')
    page.assert_selector('.iban-offer-form__heading')
    page.assert_selector('.iban-offer-form__desc_detail')
    page.assert_selector('.btn-primary[disabled]', count: 1)
  end

end
