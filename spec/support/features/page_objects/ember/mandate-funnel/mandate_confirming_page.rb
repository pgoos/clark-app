require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/page_objects/ember/mandate-funnel/mandate_profiling_page"

class MandateConfirmingPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @path_to_confirming_page = "/#{locale}/app/mandate/confirming"
    @path_to_finished_page = "/#{locale}/app/mandate/finished"
    @mandate_profiling_po = MandateProfilingPage.new
  end

  def visit_confirming
    visit @path_to_confirming_page
  end

  def shows_current_step(number)
    expect(find(".mandate_process_number__amount").text).to include(number.to_s)
  end

  def expect_confirming_page
    assert_current_path(@path_to_confirming_page)
    assert_selector(".mandate-confirmation__process__wrapper")
    assert_selector(".mandate-confirmation__signature")
    assert_selector(".mandate-confirmation__signature__cta")
  end

  def scroll_down
    Capybara.current_session.execute_script("window.scrollTo(0, 500);")
  end

  def expect_consent_section
    page.assert_selector(".mandate-confirmation__consent")
  end

  def open_consent_modal
    find(".mandate-confirmation__consent__link").click
    page.assert_selector(".health-data-consent-modal")
  end

  def open_tos_modal
    find(".mandate-confirmation__toggle--grey-link").click
  end

  def expect_point_of_contact(name)
    expect(find(".mandate-confirmation__mandate__signature-block").text).to include(name)
  end

  def expect_no_point_of_contact
    expect(page).not_to have_selector(".mandate-confirmation__mandate__signature-block")
  end

  def expect_sigature_in_tos_modal
    page.assert_selector(".mandate-confirmation__mandate__signature")
  end

  def expect_no_sigature_in_tos_modal
    expect(page).not_to have_selector(".mandate-confirmation__mandate__signature")
  end

  def expect_tos_modal_contains(brand)
    expect(find(".mandate-confirmation__modal__details").text).to include(brand)
  end

  def sign_form_weiter
    @mandate_profiling_po.sign_form_weiter
  end

  def click_jetz_unterschreiben
    @mandate_profiling_po.click_jetz_unterschreiben
  end

  def shows_trust_modal_box
    page.assert_selector(".mandate-confirmation__trust")
  end

  def get_confirmed_mandate(mandate)
    mandate = mandate
    mandate.signatures.create(
      asset: Rack::Test::UploadedFile.new(Core::Fixtures.fake_signature_file_path,
                                          document_type: DocumentType.mandate_document)
    )
    mandate.info["wizard_steps"] = %w[targeting profiling confirming]
    mandate.tos_accepted_at = 1.minute.ago
    mandate.confirmed_at = 1.minute.ago
    mandate.state = "created"
    mandate.save!
    mandate.reload
    mandate
  end

  def set_modal_box_have_variant
    trust_variation = "{\"variation\":\"confirmation-broker-mandate-tn\"}"
    executing_line = "window.localStorage.setItem('trust_confirmation_step', '#{trust_variation}')"
    Capybara.current_session.execute_script executing_line
  end

  def clear_local_storage
    executing_line = "window.localStorage.removeItem('trust_confirmation_step')"
    Capybara.current_session.execute_script executing_line
  end
end
