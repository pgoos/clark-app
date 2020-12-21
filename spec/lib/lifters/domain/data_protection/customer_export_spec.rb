# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection::CustomerExport do
  let(:admin) { create(:admin) }
  let(:mandate) { create(:mandate) }

  before do
    allow(Settings.ops_ui.mandate).to receive(:export_enabled).and_return(true)
  end

  describe "#call" do
    it "sets status to mandate and runs backgroud job" do
      expect(mandate).to receive :save!
      expect(mandate.info).to eq("wizard_steps" => [])
      expect(::DataProtection::CustomerExportJob).to receive :perform_later
      described_class.call(admin, mandate)
      expect(mandate.info).to eq("wizard_steps" => [], "status_data_protection" => "CustomerExport")
    end
  end

  it "returns #name" do
    expect(described_class.strategy_name).to eq "CustomerExport"
  end

  it "returns #command_job" do
    expect(described_class.command_job).to eq ::DataProtection::CustomerExportJob
  end

  describe ".run" do
    it "runs strategy and finalize mandate status" do
      mandate.info = {"wizard_steps" => [], "status_data_protection" => "CustomerCommand"}
      strategy = double("strategy")
      allow(strategy).to receive :run
      allow(strategy).to receive(:mandate).and_return(mandate)
      allow(mandate).to receive :save!
      service = described_class.new(admin, mandate)
      expect(service).to receive(:strategy).at_least(:once).and_return(strategy)
      service.run
      expect(mandate.info).to eq("wizard_steps" => [])
    end
  end

  describe ".notice_running_message" do
    it "returns message for running state" do
      expect(described_class.notice_running_message).to(
        eq(I18n.t("admin.mandates.export.in_progress"))
      )
    end
  end

  describe ".notice_started_message" do
    it "returns message for started state" do
      expect(described_class.notice_started_message).to(
        eq(I18n.t("admin.mandates.export.started"))
      )
    end
  end
end
