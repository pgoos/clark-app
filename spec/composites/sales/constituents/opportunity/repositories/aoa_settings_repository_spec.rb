# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::AoaSettingsRepository, :integration do
  before do
    allow(Settings.aoa).to receive(:test_group).and_return("50")
    allow(Settings.aoa).to receive(:api_url).and_return("https://aoa.test-staging.clark-de.flfinteche.de")
    allow(Settings.aoa).to receive(:current_version).and_return("default_string")
    allow(Settings.aoa.versions.default_string).to receive(:name).and_return("default_string_name")
  end

  after do
    allow(Settings.aoa).to receive(:test_group).and_call_original
    allow(Settings.aoa).to receive(:api_url).and_call_original
    allow(Settings.aoa).to receive(:current_version).and_call_original
    allow(Settings.aoa.versions.default_string).to receive(:name).and_call_original
  end

  describe "#aoa_test_group" do
    it "returns aoa aoa_test_group value" do
      expect(subject.aoa_test_group).to eq(Settings.aoa.test_group)
    end
  end

  describe "#aoa_api_url" do
    it "returns aoa aoa_api_url value" do
      expect(subject.aoa_api_url).to eq(Settings.aoa.api_url)
    end
  end

  describe "#aoa_current_version" do
    it "returns aoa aoa_current_version value" do
      expect(subject.aoa_current_version).to eq(Settings.aoa.current_version)
    end
  end

  describe "#aoa_current_version_value_of" do
    it "returns aoa aoa_current_version_value_of value" do
      expect(subject.aoa_current_version_value_of("name")).to eq(Settings.aoa.versions.default_string.name)
    end
  end
end
