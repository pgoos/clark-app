# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::Adwords::AdwordsCostUpdate do
  subject { Domain::Cost::Adwords::AdwordsCostUpdate.new(cost_attributes) }

  let(:provider_data) do
    {
      keyword_match_type: "Exact",
      max_cpc:            123,
      clicks:             1,
      avg_position:       1.5,
      ctr:                0.1
    }
  end

  let(:cost_attributes) do
    {
      start_report_interval: Time.zone.yesterday.beginning_of_day,
      end_report_interval:   Time.zone.yesterday.end_of_day,
      ad_provider:           Domain::Cost::Adwords::GdnUacParser.vendor,
      campaign_name:         "Campaign X",
      adgroup_name:          "Adgroup y",
      creative_name:         "Search Keyword z",
      cost_cents:            987,
      cost_currency:         "EUR",
      provider_data:         provider_data
    }
  end

  it "should be a Domain::Cost::AdvertiserCostUpdate" do
    expect(subject).to be_a(Domain::Cost::AdvertiserCostUpdate)
  end

  it "can be persisted" do
    expect(subject.invoke).to be_persisted
  end

  context "data exists" do
    before do
      subject.invoke
    end

    it "should not add an entry, if it is the same data" do
      expect {
        subject.invoke
      }.to change { AdvertisementPerformanceLog.count }.by(0)
    end

    it "should create a new entry, if the keyword match types are different" do
      provider_data[:keyword_match_type] = "Broad"
      expect {
        subject.invoke
      }.to change { AdvertisementPerformanceLog.count }.by(1)
    end

    it "should not create a new entry, if the max_cpc are different" do
      provider_data[:max_cpc] = 321
      expect {
        subject.invoke
      }.to change { AdvertisementPerformanceLog.count }.by(0)
    end

    it "should create a new entry, if the keywords are different" do
      provider_data[:clicks] = 2
      expect {
        subject.invoke
      }.to change { AdvertisementPerformanceLog.count }.by(0)
    end

    it "should create a new entry, if the keywords are different" do
      provider_data[:avg_position] = 2.3
      expect {
        subject.invoke
      }.to change { AdvertisementPerformanceLog.count }.by(0)
    end

    it "should create a new entry, if the keywords are different" do
      provider_data[:ctr] = 0.2
      expect {
        subject.invoke
      }.to change { AdvertisementPerformanceLog.count }.by(0)
    end
  end
end
