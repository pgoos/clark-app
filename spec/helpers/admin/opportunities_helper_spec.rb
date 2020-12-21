# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::OpportunitiesHelper, type: :helper do
  describe "#offer_accept_modal_forbidden?" do
    let(:opportunity) { build_stubbed(:opportunity, :offer_phase, offer: build_stubbed(:single_offer_product)) }
    let(:offer) { opportunity.offer }
    let(:admin) { instance_double(Admin) }
    let(:opportunity_without_offer) { build_stubbed(:opportunity, :offer_phase) }

    before do
      allow(admin).to receive(:permitted_to?).with(any_args).and_return(false)
      offer.state = "active"
      allow(controller).to receive(:current_admin).and_return(admin)
    end

    it "returns false, if the event is not :complete" do
      expect(helper.offer_accept_modal_forbidden?(:other, opportunity)).to be(false)
    end

    it "returns true, if the event is :complete" do
      expect(helper.offer_accept_modal_forbidden?(:complete, opportunity)).to be(true)
    end

    it "returns true, if opportunity does not has an offer" do
      expect(helper.offer_accept_modal_forbidden?(:complete, opportunity_without_offer)).to be(true)
    end

    context "when evaluating the offer" do
      before do
        allow(admin)
          .to receive(:permitted_to?)
          .with(controller: "admin/offers", action: "accept_offer")
          .and_return(true)
      end

      it "returns true if accepted" do
        offer.state = "accepted"
        expect(helper.offer_accept_modal_forbidden?(:complete, opportunity)).to be(true)
      end

      it "returns false if active" do
        expect(helper.offer_accept_modal_forbidden?(:complete, opportunity)).to be(false)
      end
    end

    context "when evaluating admin permissions" do
      it "returns false if admin is permitted" do
        allow(admin)
          .to receive(:permitted_to?)
          .with(controller: "admin/offers", action: "accept_offer")
          .and_return(true)
        expect(helper.offer_accept_modal_forbidden?(:complete, opportunity)).to be(false)
      end
    end
  end
end
