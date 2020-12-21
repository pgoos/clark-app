# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Constituents::UpgradeJourney::Repositories::Mappings::UpgradeJourneyState do
  describe ".entity_value" do
    context "when wizards steps include confirming" do
      it { expect(described_class.entity_value(%w[profiling confirming])).to eq "finished" }
    end

    context "when wizards steps include profiling" do
      it { expect(described_class.entity_value(%w[profiling])).to eq "signature" }
    end

    context "when wizards steps include targeting" do
      it { expect(described_class.entity_value(%w[targeting])).to eq "profile" }
    end

    context "when wizards steps are empty" do
      it { expect(described_class.entity_value(%w[])).to eq "profile" }
    end
  end

  describe ".activerecord_value" do
    context "when state is finished" do
      it { expect(described_class.activerecord_value("finished")).to eq %w[profiling confirming] }
    end

    context "when state is at signature" do
      it { expect(described_class.activerecord_value("signature")).to eq %w[profiling] }
    end

    context "when state is at profile" do
      it { expect(described_class.activerecord_value("profile")).to eq %w[] }
    end

    context "when state is blank" do
      it { expect(described_class.activerecord_value(nil)).to eq %w[] }
    end
  end
end
