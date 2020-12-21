# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection::CustomerCommand do
  let(:admin) { create(:admin) }
  let(:mandate) { create(:mandate) }

  before do
    allow(described_class).to receive(:enabled?).and_return(true)
    allow(described_class).to receive(:notice_started_message).and_return("started")
  end

  describe "#call" do
    it "sets status to mandate and runs backgroud job" do
      job = double("job")
      allow(job).to receive :perform_later
      expect(mandate).to receive :save!
      expect(mandate.info).to eq("wizard_steps" => [])
      expect(described_class).to receive(:command_job).and_return(job)
      expect(described_class).to receive(:strategy_name).and_return("CustomerCommand")
      described_class.call(admin, mandate)
      expect(mandate.info).to eq("wizard_steps" => [], "status_data_protection" => "CustomerCommand")
    end
  end

  it "raises error for #name" do
    expect { described_class.strategy_name }.to raise_error("Not Implemented")
  end

  it "raises error for #command_job" do
    expect { described_class.command_job }.to raise_error("Not Implemented")
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
end
