# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PartnershipsHelper, type: :helper do
  let(:mandate) { create(:mandate) }

  describe ".get_payout_price" do
    context "referral program" do
      it "returns the right payout mapping for referral program" do
        expect(helper.get_payout_price(mandate, described_class::REFERRAL_PROGRAM))
          .to eq(described_class:: PAYOUT_MAPPING[described_class::REFERRAL_PROGRAM])
      end
    end

    context "other partners" do
      let(:payout_amount) { 50 }
      let(:partner_ident) { "partner" }

      before do
        allow_any_instance_of(Domain::Partners::PartnerPayout).to receive(:payout_amount).and_return(payout_amount)
      end

      it "calls the partner payout lifter to fetch the payout amount" do
        expect_any_instance_of(Domain::Partners::PartnerPayout).to receive(:payout_amount)
        helper.get_payout_price(mandate, partner_ident)
      end

      it "fetches the payout amount from the partner payout lifter correctly" do
        expect(helper.get_payout_price(mandate, partner_ident))
          .to eq(payout_amount)
      end
    end
  end
end
