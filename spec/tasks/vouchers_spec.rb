# frozen_string_literal: true

require "rails_helper"

RSpec.describe "vouchers:sync_source_to_mandates", type: :task do
  let(:existing_source) { "existing_source" }
  let(:existing_campaign) { "existing_campaign" }
  let(:voucher) { create(:voucher) }
  let(:user) {
    create(
      :user,
      source_data: {
        adjust: {
          network: existing_source,
          campaign: existing_campaign
        }
      }
    )
  }
  let!(:mandate) { create(:mandate, :with_user, user: user, voucher: voucher) }

  before do
    allow(STDOUT).to receive(:puts).and_return(true)
  end

  context "when voucher_id is not passed" do
    it "it prints the error usage message" do
      expect(STDOUT)
        .to receive(:puts).with("Error: Usage bundle exec rake vouchers:sync_source_to_mandates[voucher_id]")

      task.invoke
    end
  end

  context "it prints the error usage message" do
    let(:voucher_id) { 99 }

    it "it prints the not found error message" do
      expect(STDOUT)
        .to receive(:puts).with("Error: voucher with id: #{voucher_id} doesn't exist")
      task.invoke(voucher_id)
    end
  end

  context "when voucher is missing campaign metadata" do
    let(:double_voucher) { instance_double(Voucher, metadata: { "source" => "test_source" }) }

    before do
      allow(Voucher).to receive(:find_by).with(id: voucher.id).and_return(double_voucher)
    end

    it "it prints the source missing error messages" do
      expect(STDOUT)
        .to receive(:puts).with("Error: voucher doesn't have values for campaign and source")
      task.invoke(voucher.id)
    end

    it "does not override the mandate source data network" do
      task.invoke(voucher.id)
      expect(mandate.user.reload.source_data["adjust"]["network"]).to eq(existing_source)
    end

    it "does not override the mandate source data campaign" do
      task.invoke(voucher.id)
      expect(mandate.user.reload.source_data["adjust"]["campaign"]).to eq(existing_campaign)
    end
  end

  context "when voucher is missing source metadata" do
    let(:double_voucher) { instance_double(Voucher, metadata: { "campaign" => "test_campaign" }) }

    before do
      allow(Voucher).to receive(:find_by).with(id: voucher.id).and_return(double_voucher)
    end

    it "it prints the source missing error messages" do
      expect(STDOUT)
        .to receive(:puts).with("Error: voucher doesn't have values for campaign and source")
      task.invoke(voucher.id)
    end

    it "does not override the mandate source data network" do
      task.invoke(voucher.id)
      expect(mandate.user.reload.source_data["adjust"]["network"]).to eq(existing_source)
    end

    it "does not override the mandate source data campaign" do
      task.invoke(voucher.id)
      expect(mandate.user.reload.source_data["adjust"]["campaign"]).to eq(existing_campaign)
    end
  end

  context "the mandate is associated with a lead" do
    let!(:mandate) { create(:mandate, :with_lead, voucher: voucher) }

    it "sets the lead source network to the voucher campaign source" do
      task.invoke(voucher.id)

      expect(mandate.lead.reload.source_data["adjust"]["network"]).to eq(voucher.metadata["source"])
    end

    it "sets the lead source campaign to the voucher campaign" do
      task.invoke(voucher.id)

      expect(mandate.lead.reload.source_data["adjust"]["campaign"]).to eq(voucher.metadata["campaign"])
    end
  end

  context "the mandate is associated with a user" do
    let!(:mandate) { create(:mandate, :with_user, voucher: voucher) }

    it "sets the user source network to the voucher campaign source" do
      task.invoke(voucher.id)

      expect(mandate.user.reload.source_data["adjust"]["network"]).to eq(voucher.metadata["source"])
    end

    it "sets the user source campaign to the voucher campaign" do
      task.invoke(voucher.id)

      expect(mandate.user.reload.source_data["adjust"]["campaign"]).to eq(voucher.metadata["campaign"])
    end
  end
end
