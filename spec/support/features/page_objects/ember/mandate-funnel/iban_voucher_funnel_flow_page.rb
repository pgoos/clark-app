# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/feature_helpers"
require "./spec/support/features/page_objects/ember/mandate-funnel/cockpit_preview_page"
require "./spec/support/features/page_objects/ember/mandate-funnel/select-category/category_page"
require "./spec/support/features/page_objects/ember/mandate-funnel/select-category/company_page"
require "./spec/support/features/page_objects/ember/mandate-funnel/mandate_profiling_page"
require "./spec/support/features/page_objects/ember/mandate-funnel/mandate_confirming_page"
require "./spec/support/features/page_objects/ember/mandate-funnel/mandate_register_page"
require "./spec/support/features/page_objects/ember/mandate-funnel/mandate_finished_page"

class IbanVoucherFunnelFlowPage < PageObject
  def initialize(locale=I18n.locale)
    @path_to_status              = "/#{locale}/app/mandate/status"
    @path_to_cockpit_preview     = "/#{locale}/app/mandate/cockpit-preview"
    @path_to_cockpit_targeting   = "/#{locale}/app/mandate/targeting"
    @cockpit_preview_page        = CockpitPreviewPage.new
    @select_category_page_object = SelectCategoryPage.new
    @select_company_page_object  = SelectCompanyPage.new
    @profiling_page_object       = MandateProfilingPage.new
    @confirming_page_object      = MandateConfirmingPage.new
    @iban_page_object            = MandateIbanPage.new
    @register_page_object        = MandateRegisterPage.new
    @finished_page_object        = MandateFinishedPage.new
  end

  # Page interactions ------------------------------------------------------------------------------

  def visit_page
    visit @path_to_page
  end

  def visit_route(route)
    visit route
  end

  def visit_status
    visit @path_to_status
    assert_current_path @path_to_status

    assert_selector(".wizard-status__inner")
  end

  def visit_status_generic
    visit @path_to_status
    assert_current_path @path_to_status
    assert_selector(".wizard-status__inner")
  end

  def visit_cockpit_preview
    visit @path_to_cockpit_preview
    assert_current_path @path_to_cockpit_preview
  end

  def visit_cockpit_targeting
    visit @path_to_cockpit_targeting
    assert_current_path @path_to_cockpit_targeting
  end

  def click_cta
    find(".btn-primary").click
  end

  def click_category(category_id)
    @select_category_page_object.click_item(category_id)
  end

  def click_company(company_id)
    @select_company_page_object.click_item(company_id)
  end

  def navigate_click(classname, location)
    find(classname).click
    assert_current_path(location)
  end

  def expect_cockpit_preview
    @cockpit_preview_page.expect_cockpit_preview_page
  end

  def expect_cockpit_targeting
    @select_category_page_object.expect_targeting_page
  end

  def expect_company_selection_page
    @select_company_page_object.expect_company_page
  end

  def expect_profiling
    @profiling_page_object.expect_mandate_profiling_page
  end

  def fill_in_profiling
    @profiling_page_object.fill_in_form_with_email
  end

  def fill_in_profiling_with_voucher(voucher)
    @profiling_page_object.fill_in_form_with_email
    fill_in "mandate_voucher_code", with: voucher.code
  end

  def visit_confirming
    @confirming_page_object.visit_confirming
    Capybara.current_session.execute_script("$('#insign-iframe').removeAttr('src')")
  end

  def expect_confirming_page
    @confirming_page_object.expect_confirming_page
  end

  def expect_confirming_page
    find("#mandateSignatureModal").send_keys [:delete]
    Capybara.current_session.execute_script("$('#mandateSignatureModal').remove();")
    Capybara.current_session.execute_script("$('#insign-iframe').remove();")
    @confirming_page_object.expect_confirming_page
  end

  def get_confirmed_lead(lead)
    mandate = lead.mandate
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
    lead.reload
    mandate
  end

  def get_confirmed_lead_iban(lead, voucher=nil)
    mandate = lead.mandate
    mandate.signatures.create(
      asset: Rack::Test::UploadedFile.new(Core::Fixtures.fake_signature_file_path,
                                          document_type: DocumentType.mandate_document)
    )
    mandate.info["wizard_steps"] = %w[targeting profiling confirming]
    mandate.tos_accepted_at = 1.minute.ago
    mandate.confirmed_at = 1.minute.ago
    mandate.created_at = 1.minute.ago
    mandate.state = "created"
    mandate.voucher = voucher
    mandate.save!
    lead.reload
    mandate
  end

  def expect_iban_page
    @iban_page_object.expect_iban_page
  end

  def expect_success_page
    @finished_page_object.expect_finished_page
  end

  def expect_register_page
    @register_page_object.expect_correct_elements
    @register_page_object.fill_password
  end

  def expectcta
    find(".btn-primary")
  end
end
