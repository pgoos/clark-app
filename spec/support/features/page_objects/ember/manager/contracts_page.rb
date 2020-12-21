# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"

class ContractsPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale = locale
    @path_to_cockpit = "/#{@locale}/app/manager"
  end

  # Page interactions ------------------------------------------------------------------------------

  # Helpers for all of the iban / notifications on the contracts page
  def visit_page
    visit @path_to_cockpit
    Capybara.current_session.execute_script "window.sessionStorage.setItem('clark-spash-screen', 'false');"
    Capybara.current_session.execute_script "window.localStorage.setItem('manager', '{}');"
    Capybara.current_session.execute_script "window.localStorage.setItem('reminders-since-mandate', 3);"
    begin
      find("i.ember-modal__body__close", wait: 5).click
      assert_no_text(I18n.t("manager.demandcheck_reminder.title"), wait: 5)
    rescue Capybara::ElementNotFound
      # this means modal was closed or simple didn't appear
    end
  end

  def expect_manager
    page.assert_current_path (@path_to_cockpit)
  end

  def expect_skeleton_gone
    page.assert_selector(".capybara-contracts-list", wait: 60)
  end

  def expect_no_notification
    page.assert_no_selector(".manager__notification--long")
  end

  def expect_notification
    page.assert_selector(".manager__notification--long")
  end

  def set_seen_iban_notification
    Capybara.current_session.execute_script(
      "window.localStorage.setItem('manager', '{ \"seenIbanNotification\": true }');"
    )
  end

  def set_seen_mam_notification
    Capybara.current_session.execute_script(
      "window.localStorage.setItem('manager', '{ \"seenMamNotification\": true }');"
    )
  end

  def refresh_page_for_cookie_changes
    Capybara.current_session.driver.browser.navigate.refresh
  end

  def expect_no_product_add_notification
    page.assert_no_selector(".manager__notification_partner--long")
  end

  def expect_product_add_notification
    page.assert_selector(".manager__notification_partner--long")
  end

  def set_seen_product_add_notification
    Capybara.current_session.execute_script(
      "window.localStorage.setItem('manager', '{ \"seenProductAddLaterMsg\": true }');"
    )
  end

  # Top row with the demand check states
  def expect_do_demandcheck_state
    page.assert_selector(".capybara-do-demandcheck")
  end

  def expect_demandcheck_cta_to_work
    navigate_click(
      ".capybara-do-demandcheck",
      "demandcheck/intro"
    )
  end

  def expect_and_click_first_opportunity
    opp = find(".capybara-opportunity-card")
    opp.assert_text("Angebot verfügbar")
    opp.click
  end

  def expect_no_opportunity(life_aspect)
    page.assert_no_selector(".manager__contracts__cards-list__aspect--#{life_aspect}")
  end

  def expect_cta_for_add_insurance_works
    find(".manager__cockpit__add-insurances-cta__btn").click
    page.assert_selector(".ember-modal__body__header--add-more-insurance")
    navigate_click(".add-category-modal__btn--pkv", "mandate/targeting")
  end

  def expect_functional_placeholder_products(category_id)
    find(".manager__placeholder-products__product").click
    page.assert_selector(".ember-modal__body__header--placeholder-products")
    navigate_click(
      ".ember-modal__body__footer__cta:nth-child(1)",
      "mandate/targeting/company/#{category_id}"
    )
  end

  def click_placeholder_product
    find(".capybara-placeholder-card").click
  end

  def expect_functional_add_more_insurances
    page.assert_selector(".ember-modal__body__header--add-more-insurance")
    navigate_click(".ember-modal__body__footer__cta", "mandate/targeting")
  end

  def expect_functional_add_bu_modal(questionnaire_ident)
    page.assert_selector(".ember-modal__body__header--add-bu-insurance")
    navigate_click(".ember-modal__body__footer__cta", "questionnaire/#{questionnaire_ident}")
  end

  def expect_bu_modal_not_present
    page.assert_no_selector ".ember-modal__body__header--add-bu-insurance"
  end

  def expect_score_but_no_totals
    page.assert_no_selector(".capybara-do-demandcheck")
    page.assert_no_selector(".capybara-overview-totals")
  end

  def expect_score_and_totals
    page.assert_no_selector(".capybara-do-demandcheck")
    page.assert_selector(".capybara-overview-totals")
  end

  def expect_no_advice_banner
    expect(page).not_to have_selector(".manager__products-list__product__notification-row__status--advice")
  end

  def expect_no_questionnaire_status
    expect(find('.manager__products-list__product__status').text).not_to eq("#{I18n.t('manager.products.done_questionnaire.title')}")
  end

  def expect_no_offer_banner
    expect(page).not_to have_selector(".manager__products-list__product__notification-row__status--offer")
  end

  def get_confirmed_user_or_lead(user_or_lead)
    mandate = user_or_lead.mandate
    mandate.signatures.create(
      asset: Rack::Test::UploadedFile.new(
        Core::Fixtures.fake_signature_file_path
      )
    )
    mandate.info["wizard_steps"] = %w[targeting profiling confirming]
    mandate.tos_accepted_at = 1.minute.ago
    mandate.confirmed_at = 1.minute.ago
    mandate.state = "created"
    mandate.save!

    mandate.reload
    user_or_lead.reload
    mandate
  end

  # Clicking on an item with x class should take us to y page
  def navigate_click(classname, location)
    page.assert_selector(classname)
    find(classname).click
    page.assert_current_path("/#{locale}/app/#{location}")
  end
end
