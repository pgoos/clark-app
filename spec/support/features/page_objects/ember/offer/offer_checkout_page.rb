require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/page_objects/ember/ember_helper"

class OfferCheckoutPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale      = locale
    # @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------
  def navigate(offer_id, option_id)
    visit "#{locale}/app/offer/#{offer_id}/checkout/#{option_id}"
  end

  def visit_page(opportunity)
    page_path = "/#{locale}/app/offer/#{opportunity.id}/checkout/" \
                "#{opportunity.offer.offer_options[1].id}"
    visit(page_path)
    page.assert_current_path(page_path)
    # Was not passing correctly without this :(
    sleep 1
  end

  def shows_correct_page_elements
    page.assert_selector(".offer-checkout__details__overview", visible: true)
    page.assert_selector(".offer-checkout__toggle-features__icon", visible: true)
    page.assert_selector(".offer-checkout__reasurance__item", visible: true, count: 2)
  end

  def shows_clark_tip
    page.assert_selector(".offer-checkout__details__tip", visible: true)
  end

  def shows_features
    page.assert_selector(".offer-checkout__features", visible: true)
  end

  def select_an_option(offer_option_id)
    find("[data-offer-option-cta=\"#{offer_option_id}\"]").click
  end

  def select_an_option_from_comparison(offer_option_id)
    locator = "[data-offer-option-cta=\"#{offer_option_id}\"]"

    # wait for the button and click on it
    button = find(locator)
    sleep 0.1 while button.disabled?
    button.click

    # handle the case when clicking the button has no effect
    3.times do
      begin
        return if find(locator).disabled?
        sleep 1
        find(locator).click
      rescue Capybara::ElementNotFound
        return
      end
    end
  end

  def select_an_option_with_more_details(offer_option_id)
    find(".offers__offer__option__cta--more-details[data-offer-option-cta=\"#{offer_option_id}\"]").click
  end

  def data_confirmation_page_has_headline(headline)
    find(".iban-offer-form__header__title").assert_text(I18n.t(headline).to_s)
  end

  def go_from_checkout_to_next
    find(".btn-primary").click
  end

  def purchase_a_product
    find(".btn-next-split").click
  end

  def accept_terms
    page.find('[for="termsCheck"]', visible: true).click
  end

  def iban_page_fill_details_and_move(iban)
    find('[for="ibanCheck"]').click
    find(".capybara-offer-iban-input").set(iban)
    find(".btn-primary").click
  end

  def purchase_confirmation_has_proper_content(headline, opportunityId)
    page.assert_selector(".offers__confirmation__header__title")
    page.assert_text(I18n.t(headline).to_s)
    page.assert_current_path("/#{@locale}/app/offer/#{opportunityId}/confirmation")
  end

  def click_toggle_features
    btn = find(".offer-checkout__toggle-features")
    btn.click
    sleep 1
  end

  # Clicking on an item with x class should take us to y page
  def navigate_click(classname, location)
    btn = find(classname)
    page.assert_current_path("/#{locale}/app/#{location}")
  end

  def navigate_to(location)
    visit "/#{locale}/app/#{location}"
  end

  def wait_for_page
    # @emberHelper.wait_for_ember_transition
  end

  def expect_manager_page
    page.assert_current_path("/#{locale}/app/manager")
  end

  def expect_login_page
    page.assert_current_path("/#{locale}/login")
  end

  def fill_in_iban(iban_number)
    fill_in "iban", with: iban_number
  end
end
