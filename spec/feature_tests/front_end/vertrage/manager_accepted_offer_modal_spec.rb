# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/manager/nps_model_page"
require "./spec/support/features/page_objects/ember/offer/offer_checkout_page"
require "./spec/support/features/page_objects/ember/manager/manager_accepted_offer_modal_page"
require "./spec/support/features/page_objects/ember/manager/cockpit_items"

RSpec.describe "Manager - accepted offer feedback modal", :clark_context, :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let(:modal_helper) { ManagerAcceptedOfferModal.new }
  let(:offer_page) { OfferCheckoutPage.new }
  let(:cockpit_items) { CockpitItems.new }

  let(:user) do
    user = create(:user, mandate: create(:mandate), confirmed_at: Time.zone.now)
    user.mandate.info["wizard_steps"] = %w[profiling targeting confirming]
    # @TODO this needs to be changed to the real value when we know what it is
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = Date.current
    user.mandate.tos_accepted_at = Date.current
    user.mandate.state = :in_creation
    user.mandate.complete!
    user
  end

  let(:switch) do
    exposed = "RATING_MODAL"
    result = FeatureSwitch.find_by(key: exposed)
    result = FactoryBot.create(:feature_switch, key: exposed) if result.blank?
    result
  end

  context "TAKEN OVER BY EMBER ACCEPTANCE TEST" do
    before { skip("this capybara test will taken over by ember acceptance test.") }

    context "when not just accepted offer" do
      before do
        allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
        switch.update!(active: true)
        login_as(user, scope: :user)
        modal_helper.visit_page
      end

      it "should not show rate modal" do
        modal_helper.expect_no_rate_modal
      end
    end

    context "when local flag is set" do
      before do
        allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
        switch.update!(active: true)
        login_as(user, scope: :user)
        modal_helper.visit_page
        modal_helper.reset_localStorage_rating_settings
        modal_helper.set_localStorage_rateable
      end

      it "should show the rate us modal" do
        modal_helper.expect_rate_modal
      end

      after do
        modal_helper.reset_localStorage_rating_settings
      end
    end

    context "flow test from accepting an offer and seeing the modal" do
      let!(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }

      before do
        opportunity.category.update(simple_checkout: true)
        opportunity.category.update(life_aspect: "things")
        allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
        switch.update!(active: true)
        login_as(user, scope: :user)
        user.mandate.update(iban: JsHelper.sample_iban)
        modal_helper.visit_page
      end

      it "does checkout for a low marging product with IBAN" do
        # Opens the offers for a category
        cockpit_items.click_opportunity
        cockpit_items.expect_correct_page(opportunity.id)

        # Select an offer
        offer_option_id = opportunity.offer.offer_options[1].id
        offer_page.select_an_option_from_comparison(offer_option_id)

        # Thank you page
        offer_page.purchase_a_product
        offer_page.purchase_confirmation_has_proper_content(
          "manager.offers.client.offer_confirmation.page_title", opportunity.id
        )

        # go back to manager
        # reset already rated flag to see the modal
        user.mandate.update(info: {"wizard_steps": %w[targeting profiling confirming]})
        cockpit_items.visit_page

        # make sure we get the modal
        modal_helper.expect_rate_modal
      end

      after do
        modal_helper.reset_localStorage_rating_settings
      end
    end
  end
end
