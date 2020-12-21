# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Vouchers do
  let(:voucher) { create(:voucher) }
  let(:mandate) { create(:mandate, voucher: voucher) }
  let(:user)    { create(:user, mandate: mandate) }
  let(:lead)    { create(:lead, mandate: mandate) }

  describe ".update_source_data" do
    context "the update_source_data setting is on" do
      before do
        Settings.vouchers.source_data_updatable = true
      end

      context "the mandate is associated with a user" do
        it "sets the lead source network to the voucher campaign source" do
          described_class.update_source_data(user)
          expect(user.source_data["adjust"]["network"]).to eq(voucher.metadata["source"])
        end

        it "sets the user source campaign to the voucher campaign" do
          described_class.update_source_data(user)
          expect(user.source_data["adjust"]["campaign"]).to eq(voucher.metadata["campaign"])
        end
      end

      context "the mandate is associated with a lead" do
        it "sets the lead source network to the voucher campaign source" do
          described_class.update_source_data(lead)
          expect(lead.source_data["adjust"]["network"]).to eq(voucher.metadata["source"])
        end

        it "sets the lead source campaign to the voucher campaign" do
          described_class.update_source_data(lead)
          expect(lead.source_data["adjust"]["campaign"]).to eq(voucher.metadata["campaign"])
        end
      end
    end

    context "the voucher is missing campaign metadata" do
      let(:voucher) { instance_double(Voucher, metadata: {}) }
      let(:existing_source) { "existing_source" }
      let(:existing_campaign) { "existing_campaign" }
      let(:mandate) { create(:mandate) }
      let(:user) {
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

      it "does not override the source data network" do
        described_class.update_source_data(user)
        expect(user.source_data["adjust"]["network"]).to eq(existing_source)
      end

      it "does not override the source data campaign" do
        described_class.update_source_data(user)
        expect(user.source_data["adjust"]["campaign"]).to eq(existing_campaign)
      end
    end

    context "the update_source_data setting is absent" do
      before do
        Settings.vouchers.source_data_updatable = nil
      end

      it "makes no update to the source campaign" do
        described_class.update_source_data(user)
        expect(user.source_data["adjust"]).to be_falsey
      end
    end
  end
end
