# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/page_objects/ember/ember_helper"
require "./spec/support/features/page_objects/manager/wizard_confirming_page"

class MandateProfilingPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale                  = locale
    @path_to_profile_page    = "/#{locale}/app/mandate/profiling"
    @path_to_confirming_page = "/#{locale}/app/mandate/confirming"
    @path_to_finished_page   = "/#{locale}/app/mandate/finished"
    @path_to_cockpit_page    = "/#{locale}/app/manager"
    @emberHelper             = EmberHelper.new
    @wizardConfirm           = WizardConfirmingPage.new
  end

  # Page interactions ------------------------------------------------------------------------------

  def visit_page
    visit @path_to_profile_page
  end

  def visit_confirm_page
    visit @path_to_confirming_page
  end

  def click_weiter
    find_button("Weiter").click
  end

  def shows_current_step(number)
    element = find(".mandate_process_number__amount")
    element.assert_text(number)
  end

  def expect_malburg_header
    page.assert_no_selector(".phone-number")
  end

  # Shows the right form inputs and so on
  def has_correct_elements
    # form inputs
    expect(page).to have_selector("#mandate_first_name")
    expect(page).to have_selector("#mandate_last_name")
    expect(page).to have_selector("#mandate_birthdate")
    expect(page).to have_selector("#mandate_street")
    expect(page).to have_selector("#mandate_house_number")
    expect(page).to have_selector("#mandate_zipcode")
    expect(page).to have_selector("#mandate_place")
    expect(page).to have_selector("#mandate_voucher_code")
    # Male / female
    expect(page).to have_selector(".ember-radio-button", count: 2)
    # Ctas
    expect(page).to have_selector(".capybara-btn-primary")
    expect(page).to have_selector(".capybara-btn-secondary")
    expect(page).not_to have_selector("#mandate_phone")
    expect(page).not_to have_selector("#mandate_iban")
  end

  def has_malburg_profiling_elements
    page.assert_selector("#mandate_first_name")
    page.assert_selector("#mandate_last_name")
    page.assert_selector("#mandate_birthdate")
    page.assert_selector("#mandate_street")
    page.assert_selector("#mandate_house_number")
    page.assert_selector("#mandate_zipcode")
    page.assert_selector("#mandate_place")
    page.assert_no_selector("#mandate_voucer_code")
    page.assert_no_selector(".capybara-btn-secondary")
  end

  def fill_in_form
    first(".ember-radio-button")
    fill_in "mandate_first_name", with: "Gareth"
    fill_in "mandate_last_name", with: "Fuller"
    fill_in "mandate_street", with: "Fox Grove"
    fill_in "mandate_house_number", with: "2"
    fill_in "mandate_zipcode", with: "12345"
    fill_in "mandate_place", with: "UK Baby"
    fill_in "mandate_birthdate", with: "30.06.1990"
  end

  def fill_in_form_with_email
    fill_in_form
    fill_in "mandate_email", with: "test@clark.de"
  end

  def empty_form
    fill_in "mandate_first_name", with: ""
    fill_in "mandate_last_name", with: ""
    fill_in "mandate_birthdate", with: ""
    fill_in "mandate_street", with: ""
    fill_in "mandate_house_number", with: ""
    fill_in "mandate_zipcode", with: ""
    fill_in "mandate_place", with: ""
    fill_in "mandate_birthdate", with: ""
    fill_in "mandate_voucher_code", with: ""
  end

  def sign_form_weiter
    within_frame(find("#insign-iframe")) do
      element = find(:xpath, "//div[@id='signaturepad']")
      element.hover
      page.driver.browser.action.move_to(element.native, 122, 91)
          .click_and_hold
          .move_to(element.native, 120, 90)
          .move_to(element.native, 121, 88)
          .move_to(element.native, 122, 84)
          .move_to(element.native, 123, 80)
          .move_to(element.native, 124, 80)
          .move_to(element.native, 126, 81)
          .move_to(element.native, 128, 82)
          .move_to(element.native, 130, 83)
          .move_to(element.native, 132, 84)
          .move_to(element.native, 135, 85)
          .move_to(element.native, 136, 86)
          .move_to(element.native, 137, 87)
          .move_to(element.native, 138, 84)
          .move_to(element.native, 140, 82)
          .move_to(element.native, 144, 80)
          .move_to(element.native, 148, 77)
          .move_to(element.native, 153, 75)
          .move_to(element.native, 155, 72)
          .release
          .perform
    end
    @wizardConfirm.click_next
  end

  def confirm_button
    find(".capybara-btn-primary")
  end

  def shouldError(input, content, selector)
    # Clear the form each time
    fill_in_form
    fill_in(input, with: content)
    find(".capybara-btn-primary").click
    within(selector) do
      page.assert_selector(".ig__error-msg", visible: true)
    end
    page.driver.browser.navigate.refresh
  end

  # RSpec matcher ----------------------------------------------------------------------------------
  def expect_voucher
    page.assert_selector("#mandate_voucher_code")
  end

  def expect_no_voucher
    page.assert_no_selector("#mandate_voucher_code")
  end

  def expect_iban_field
    page.assert_selector('.mandate_iban')
  end

  def expect_no_iban_field
    page.assert_no_selector('.mandate_iban')
  end

  def expect_consesus_section
    page.assert_selector(".wizard-profiling__consesus")
  end

  def expect_no_consesus_section
    expect(page).not_to have_selector(".wizard-profiling__consesus")
  end

  def click_consesus_link
    find(".wizard-profiling__consesus__content__link").click
  end

  def expect_consensus_modal
    page.assert_selector(".health-data-consent-modal")
  end

  def expect_cannot_fill_in_form_inputs
    page.assert_selector(".form-list__item__input:disabled", count: 8)
  end

  def expect_can_fill_in_form_inputs
    expect(page).not_to have_selector(".form-list__item__input:disabled")
  end


  def shows_terms_checkox
    page.assert_selector(".wizard-profiling__terms")
  end

  def terms_checkbox_unchecked
    expect(page).not_to have_selector(".wizard-profiling__terms__checkbox .custom-checkbox__label--active")
  end

  def terms_checkbox_checked
    page.assert_selector(".wizard-profiling__terms__checkbox .custom-checkbox__label--active")
  end

  def click_terms_link
    find('.wizard-profiling__terms__link').click
  end

  def shows_terms_modal
    page.assert_selector("#termsModal")
  end

  def scroll_bottom
    Capybara.current_session.execute_script("window.scrollTo(0, document.body.scrollHeight);")
  end

  def close_terms_modal
    find('.ember-modal__body__footer__cta').click
  end


  def expect_mandate_profiling_page
    page.assert_selector(".wizard-profiling__intro")
  end

  def navigate_click(classname, location)
    find(classname).click
    page.assert_current_path("/#{@locale}/app/#{location}")
  end

  def navigate_click_to_confirming
    find(".capybara-btn-primary").click
    Capybara.current_session.execute_script("$('#insign-iframe').removeAttr('src')")
    page.assert_current_path("/#{locale}/app/mandate/confirming")
  end

  def click_jetz_unterschreiben
    find(".mandate-confirmation__signature__cta").click
  end


  def click_jetz_unterschreiben
    find(".mandate-confirmation__signature__cta").click
  end

  def navigate_to(location)
    @emberHelper.set_up_ember_transition_hook
    visit "/#{locale}/app/#{location}"
    @emberHelper.wait_for_ember_transition
  end

  def expect_success
    page.assert_current_path(@path_to_finished_page)
    page.assert_text(I18n.t("account.wizards.finished.headline").to_s, minimum: 1)
    page.assert_selector(".wizard-confirmation__thanks-intro")
  end

  def expect_cockpit
    page.assert_selector(".manager__cockpit")
  end

  def expect_confirming_page
    page.assert_selector(".mandate-confirmation__signature")
    page.assert_selector(".mandate-confirmation__signature__animation")
    page.assert_selector(".mandate-confirmation__signature__cta")
    page.assert_selector(".btn-primary")
  end

  def expect_insign_frame
    page.assert_selector("#insign-iframe")
  end

  def get_confirmed_mandate(mandate)
    mandate = mandate
    mandate.signatures.create(
      asset: Rack::Test::UploadedFile.new(Core::Fixtures.fake_signature_file_path)
    )
    mandate.info["wizard_steps"] = %w[targeting profiling confirming]
    mandate.tos_accepted_at = 1.minute.ago
    mandate.confirmed_at = 1.minute.ago
    mandate.state = "created"
    mandate.save!
    mandate.reload
    mandate
  end

  def expect_no_mandate_doc_link
    page.assert_no_selector('.wizard-profiling__maklerpdf')
  end

  def expect_mandate_doc_link
    page.assert_selector('.wizard-profiling__maklerpdf')
  end

  def click_cta
    find(".capybara-btn-primary").click
  end
end
