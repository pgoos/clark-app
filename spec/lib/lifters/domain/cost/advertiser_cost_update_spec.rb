# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::AdvertiserCostUpdate do

  let(:parsed_log_entry) {
    {
      start_report_interval: DateTime.strptime("2016-04-19T00:00:00.000+02:00", "%Y-%m-%dT%H:%M:%S.%N %z").utc,
      end_report_interval:   DateTime.strptime("2016-04-19T23:59:59.999+02:00", "%Y-%m-%dT%H:%M:%S.%N %z").utc,
      ad_provider:           "facebook_leverate",
      campaign_name:         "Clark Versicherungen (Android, Free, DE, 50MB, w/capping, NRB)",
      adgroup_name:          "hello",
      creative_name:         "world",
      cost_cents:            10,
      cost_currency:         "EUR"
    }
  }

  it "should create a new value, if it is not present" do
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(entry.start_report_interval).to eq(parsed_log_entry[:start_report_interval])
    expect(entry.end_report_interval).to eq(parsed_log_entry[:end_report_interval])
    expect(entry.ad_provider).to eq(parsed_log_entry[:ad_provider])
    expect(entry.campaign_name).to eq(parsed_log_entry[:campaign_name])
    expect(entry.adgroup_name).to eq(parsed_log_entry[:adgroup_name])
    expect(entry.creative_name).to eq(parsed_log_entry[:creative_name])
    expect(entry.cost_cents).to eq(parsed_log_entry[:cost_cents])
    expect(entry.cost_currency).to eq(parsed_log_entry[:cost_currency])
    expect(entry.historical_values).to eq({})
  end

  it "should update an existing value, if it is present" do
    described_class.new(parsed_log_entry).invoke
    new_value                        = AdvertisementPerformanceLog.last
    id                               = new_value.id
    parsed_log_entry[:cost_cents]    = 20
    parsed_log_entry[:cost_currency] = 'USD'
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(id).to eq(entry.id)
  end

  it "should create a new value, if the interval start is different" do
    described_class.new(parsed_log_entry).invoke
    new_value                                = AdvertisementPerformanceLog.last
    id                                       = new_value.id
    parsed_log_entry[:start_report_interval] = parsed_log_entry[:start_report_interval].advance(seconds: 1)
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(id).not_to eq(entry.id)
  end

  it "should create a new value, if the interval end is different" do
    described_class.new(parsed_log_entry).invoke
    new_value                              = AdvertisementPerformanceLog.last
    id                                     = new_value.id
    parsed_log_entry[:end_report_interval] = parsed_log_entry[:end_report_interval].advance(seconds: 1)
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(id).not_to eq(entry.id)
  end

  it "should create a new value, if the ad_provider is different" do
    described_class.new(parsed_log_entry).invoke
    new_value                      = AdvertisementPerformanceLog.last
    id                             = new_value.id
    parsed_log_entry[:ad_provider] = "other ad provider"
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(id).not_to eq(entry.id)
  end

  it "should create a new value, if the campaign name is different" do
    described_class.new(parsed_log_entry).invoke
    new_value                        = AdvertisementPerformanceLog.last
    id                               = new_value.id
    parsed_log_entry[:campaign_name] = "other ad campaign"
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(id).not_to eq(entry.id)
  end

  it "should create a new value, if the ad group name is different" do
    described_class.new(parsed_log_entry).invoke
    new_value                       = AdvertisementPerformanceLog.last
    id                              = new_value.id
    parsed_log_entry[:adgroup_name] = "other ad group"
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(id).not_to eq(entry.id)
  end

  it "should create a new value, if the ad creative name is different" do
    described_class.new(parsed_log_entry).invoke
    new_value                        = AdvertisementPerformanceLog.last
    id                               = new_value.id
    parsed_log_entry[:creative_name] = "other creative name"
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(id).not_to eq(entry.id)
  end

  it "should update the cost and store the old cost as historical value" do
    described_class.new(parsed_log_entry).invoke
    new_value                        = AdvertisementPerformanceLog.last
    updated_at                       = new_value.updated_at
    historical_value                 = new_value.cost_cents
    historical_currency              = new_value.cost_currency
    parsed_log_entry[:cost_cents]    = 20
    parsed_log_entry[:cost_currency] = "USD"
    described_class.new(parsed_log_entry).invoke
    entry = AdvertisementPerformanceLog.last
    expect(entry.cost_cents).to eq(parsed_log_entry[:cost_cents])
    expect(entry.cost_currency).to eq(parsed_log_entry[:cost_currency])
    expect(entry.historical_values).to include(updated_at.to_s => {"cost_cents" => historical_value, "cost_currency" => historical_currency})
  end
end
