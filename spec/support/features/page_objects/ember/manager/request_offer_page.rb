# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/page_objects/ember/ember_helper"

class RequestOfferPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale          = locale
    @path_to_cockpit = "/#{locale}/app/manager"
    @emberHelper     = EmberHelper.new
  end

  # Page interactions ------------------------------------------------------------------------------

  def visit_cockpit
    visit @path_to_cockpit
    # allow for the skeleton view
    page.assert_selector(".capybara-contracts-list")
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

  def get_confirmed_user(user)
    mandate = user.mandate
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
    user.reload
    mandate
  end
end
