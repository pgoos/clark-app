require 'rails_helper'
require './spec/support/features/page_objects/ember/manager/manager_dc_reminder_page'
require "./spec/support/features/page_objects/ember/manager/contracts_cockpit_page"

RSpec.describe 'Modal for demandcheck shows up', :timeout, :clark_context, :slow, :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let(:modal_object) { ManagerDcReminder.new }
  let(:contract_page_object) { ContractsCockpit.new }


  context "demancheck model pops up" do
    let!(:user) do
      user = create(:user, mandate: create(:mandate))
      user
    end

    let!(:mandate) do
      mandate = user.mandate
      mandate.signatures.create(
        asset: Rack::Test::UploadedFile.new(
          Core::Fixtures.fake_signature_file_path,
          document_type: DocumentType.mandate_document
        )
      )
      mandate.info["wizard_steps"] = %w[targeting profiling confirming]
      mandate.tos_accepted_at      = 1.minute.ago
      mandate.confirmed_at         = 1.minute.ago
      mandate.state                = "accepted"
      mandate.save!

      mandate.reload
      user.reload
      mandate
    end

    before do
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(false)
      login_as(user, scope: :user)
      contract_page_object.visit_page
    end

    # fix by: JCLARK-28280
    it "shows the modal with details of recommended category", skip: true do
      Capybara.current_session.execute_script "window.localData.setAttr('manager', 'add-insurances-seen', true);"
      modal_object.modal_shows_up
      modal_object.modal_has_title(I18n.t "manager.demandcheck_reminder.title")
      modal_object.modal_has_description(I18n.t "manager.demandcheck_reminder.content")
      modal_object.has_cta (I18n.t "manager.demandcheck_reminder.cta")
    end
  end
end
