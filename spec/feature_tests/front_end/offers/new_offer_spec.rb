# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/offer/offer_details_page_object"
require "./spec/support/features/page_objects/ember/offer/offer_pages_page"
require "./spec/support/features/page_objects/ember/offer/offer_checkout_page"

RSpec.describe "Offer details page as Clark", :browser, type: :feature, js: true,
               skip: "This test should be replaced with a QUnit test" do
  let!(:offer_details_po) { OfferDetailsPageObject.new }
  let!(:offers_po) { OfferPagesPageObject.new }
  let!(:offer_checkout_po) { OfferCheckoutPage.new }

  let(:user) do
    user = create(:user)
    user.update_attributes(mandate: create(:mandate))
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at         = Time.current
    user.mandate.tos_accepted_at      = Time.current
    user.mandate.info["wizard_steps"] = %w[targeting profiling confirming]
    user.mandate.save!
    user
  end

  context "when doing the offer flow" do
    let!(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }

    before do
      opportunity.category.update(ident: "03b12732")
      opportunity.category.update(simple_checkout: true)
      opportunity.category.update(life_aspect: "things")
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
      login_as(user, scope: :user)
      offer_details_po.visit_page(opportunity)
    end

    it "Should show the correct page content through the entire flow", :clark_context do
      # pick an offer
      offer_option_id = opportunity.offer.offer_options[1].id
      offer_checkout_po.select_an_option_from_comparison(offer_option_id)

      # Should be on iban page
      offers_po.expect_on_iban(opportunity)
      offers_po.expect_clark_service
      offers_po.expect_trust_logos
      offer_checkout_po.iban_page_fill_details_and_move(JsHelper.sample_iban)

      # Should be on the data page
      offers_po.expect_on_data(opportunity, offer_option_id)
      offers_po.expect_clark_service
      offers_po.expect_trust_logos

      offer_checkout_po.purchase_a_product
    end
  end
end
