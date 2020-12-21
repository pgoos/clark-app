# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::CustomerSignedMandate do
  let(:mandate_id) { 42 }
  let(:mandate) { double(:mandate, id: mandate_id, voucher: voucher) }

  before do
    allow(Mandate).to receive(:find).with(mandate_id).and_return(mandate)
  end

  describe ".call" do
    context "when mandate has no voucher" do
      let(:voucher) { nil }

      it "creates interaction for mandate signed without voucher" do
        expect(
          OutboundChannels::Messenger::TransactionalMessenger
        ).to receive(:customer_signed_mandate).with(mandate)

        described_class.call(mandate.id)
      end
    end

    context "when mandate has a voucher" do
      let(:voucher) { double(:voucher) }

      it "creates interaction for mandate signed with voucher" do
        expect(
          OutboundChannels::Messenger::TransactionalMessenger
        ).to receive(:voucher_customer_signed_mandate).with(mandate)

        described_class.call(mandate.id)
      end
    end
  end
end
