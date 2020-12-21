# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "fix_voucher_source_attribution"

RSpec.describe FixVoucherSourceAttribution, :integration do
  let(:voucher) { create(:voucher) }
  let(:mandate) { create(:mandate, voucher: voucher) }

  describe "#up" do
    context "the mandate is associated with a user" do
      let!(:user) { create(:user, mandate: mandate) }

      it "sets the user source network to the voucher campaign source" do
        described_class.new.up
        expect(user.reload.source_data["adjust"]["network"]).to eq(voucher.metadata["source"])
      end

      it "sets the user source campaign to the voucher campaign" do
        described_class.new.up
        expect(user.reload.source_data["adjust"]["campaign"]).to eq(voucher.metadata["campaign"])
      end
    end

    context "the mandate is associated with a lead" do
      let!(:lead) { create(:lead, mandate: mandate) }

      it "sets the lead source network to the voucher campaign source" do
        described_class.new.up
        expect(lead.reload.source_data["adjust"]["network"]).to eq(voucher.metadata["source"])
      end

      it "sets the lead source campaign to the voucher campaign" do
        described_class.new.up
        expect(lead.reload.source_data["adjust"]["campaign"]).to eq(voucher.metadata["campaign"])
      end
    end
  end

  context "the voucher is missing campaign metadata" do
    let(:voucher) { instance_double(Voucher, metadata: {}) }
    let(:existing_source) { "existing_source" }
    let(:existing_campaign) { "existing_campaign" }
    let(:mandate) { create(:mandate) }
    let!(:user) {
      create(
        :user,
        mandate: mandate,
        source_data: {
          adjust: {
            network: existing_source,
            campaign: existing_campaign
          }
        }
      )
    }

    before do
      allow(mandate).to receive(:voucher).and_return(voucher)
    end

    it "does not override the mandate source data network" do
      described_class.new.up
      expect(user.reload.source_data["adjust"]["network"]).to eq(existing_source)
    end

    it "does not override the mandate source data campaign" do
      described_class.new.up
      expect(user.reload.source_data["adjust"]["campaign"]).to eq(existing_campaign)
    end
  end
end
