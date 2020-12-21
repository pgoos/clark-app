# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/manager/manager_number_one_rec_modal"



RSpec.describe "Modal for number one recommendation shows up", :slow, :timeout, :clark_context, :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let(:managerNumberOneRecPageObject) { ManagerNumberOneRecModal.new }
  let(:optimization_page_object) { OptimizationTab.new }

  context "user has a number on recommendation available" do
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

    let(:questionnaire) { create(:questionnaire) }
    let(:category) {
      create(
        :bu_category,
        questionnaire: questionnaire,
        priority:      10,
        name:          "AB",
        life_aspect:   "health"
      )
    }
    let(:recommendation) {
      create(
        :recommendation,
        mandate:  mandate,
        category: category
      )
    }

    before do
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
      login_as(user, scope: :user)
      recommendation
      optimization_page_object.visit_page
    end

    it "shows the modal with details of recommended category" do
      managerNumberOneRecPageObject.modal_shows_up
      managerNumberOneRecPageObject.modal_has_description(
        I18n.t("category_pages.3d439696.consultant_comment")
      )
      managerNumberOneRecPageObject.category_has_name("AB")
      managerNumberOneRecPageObject.has_cta("Mehr Informationen")
      managerNumberOneRecPageObject.expect_agent_picture
      managerNumberOneRecPageObject.expect_agent("Alexander Schecher")
      managerNumberOneRecPageObject.expect_agent_role("Senior Berater")

    end
  end
end
