require 'rails_helper'
require './spec/support/features/page_objects/ember/manager/optimization_tab_page'


RSpec.describe "on the optimisations page", :browser, type: :feature, js: true, skip: true do

  let(:locale) { I18n.locale }
  let(:optimization_page_object) { OptimizationTab.new }

  let!(:user) {
    user = create(:user, source_data: {"adjust": {"network": "assona"}}, mandate: create(:mandate))
    user.mandate.info["wizard_steps"] = ["targeting", "profiling", "confirming"]
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.state  = :in_creation
    user.mandate.save!
    user
  }

  let!(:optimisation) { create(:recommendation, mandate: user.mandate)}

  context "given I have a questioannaire in progress for an optimisation" do
    before do
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
      allow_any_instance_of(ClarkAPI::V3::Entities::Recommendation).to receive(:customer_finished_questionnaire).and_return(true)
      login_as(user, scope: :user)
      optimization_page_object.visit_page
      optimization_page_object.expect_no_skeleton
    end

    it "it shows the corrects sate and does not allow the user to click" do
      optimization_page_object.expect_questionnaire_in_progress_card_state
      optimization_page_object.click_card(optimisation.id)
      optimization_page_object.expect_no_modal
    end
  end

  context "Given I have a questionnaire in progress and an offer for an item" do
    let!(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }

    before do
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
      allow_any_instance_of(ClarkAPI::V3::Entities::Recommendation).to receive(:customer_finished_questionnaire).and_return(true)
      allow_any_instance_of(ClarkAPI::V3::Entities::Recommendation).to receive(:offer_id).and_return(opportunity.offer.id)
      login_as(user, scope: :user)
      optimization_page_object.visit_page
      optimization_page_object.expect_no_skeleton
    end

    it "does not show the status 'questionnaire will be analyzed'" do
      optimization_page_object.expect_no_questionnaire_in_progress_card_state
      optimization_page_object.click_card(optimisation.id)
      sleep 1
      optimization_page_object.expect_navigated_to_offer(opportunity.offer.id)
    end
  end

  context "given I have not got a questionnaire in progress for the optimisation" do

    before do
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
      allow_any_instance_of(ClarkAPI::V3::Entities::Recommendation).to receive(:customer_finished_questionnaire).and_return(false)
      login_as(user, scope: :user)
      optimization_page_object.visit_page
      optimization_page_object.expect_no_skeleton
    end

    it "it shows the normal state of the card, and opens the modal on clicking" do
      optimization_page_object.expect_no_questionnaire_in_progress_card_state
      optimization_page_object.click_card(optimisation.id)
      optimization_page_object.expect_modal
    end
  end
end
