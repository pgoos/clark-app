# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::AdvertisementPerformanceLog::Importer::Entry do
  let(:ad_provider) { Faker::Lorem.words(number: 1).join }
  let(:brand) { true }
  let(:campaign_name) { Faker::Lorem.words(number: 2).join(" ") }
  let(:cost_cents) { Faker::Number.number(digits: 4) }
  let(:day) { Faker::Date.between(from: 1.year.ago, to: Date.today).strftime("%d.%m.%Y") }
  let(:data) {
    {
      id: 1,
      brand: brand,
      ad_provider: ad_provider,
      campaign_name: campaign_name,
      cost_cents: cost_cents,
      day: day
    }
  }

  describe "#valid?" do
    context "when provided data are not valid" do
      it "returns false when ad_provider is missing" do
        data.delete(:ad_provider)

        entry = described_class.new(data)
        expect(entry).not_to be_valid
      end

      it "returns false when brand is missing" do
        data.delete(:brand)

        entry = described_class.new(data)
        expect(entry).not_to be_valid
      end

      it "returns false when campaign_name is missing" do
        data.delete(:campaign_name)

        entry = described_class.new(data)
        expect(entry).not_to be_valid
      end

      it "returns false when cost_cents is missing" do
        data.delete(:cost_cents)

        entry = described_class.new(data)
        expect(entry).not_to be_valid
      end

      it "returns false when day is missing" do
        data.delete(:day)

        entry = described_class.new(data)
        expect(entry).not_to be_valid
      end

      it "returns false when day format is not correct" do
        data[:day] = Faker::Date.between(from: 1.year.ago, to: Date.today).strftime("%Y-%m-%d")

        entry = described_class.new(data)
        expect(entry).not_to be_valid
      end

      it "returns false when cost_cents is not integer" do
        data[:cost_cents] = "123.12"

        entry = described_class.new(data)
        expect(entry).not_to be_valid
      end
    end

    context "when provided data are valid" do
      it "returns true" do
        entry = described_class.new(data)
        expect(entry).to be_valid
      end
    end
  end

  describe "#insert!" do
    let(:entry) { described_class.new(data) }

    context "when provided data are not valid" do
      it "doesn't initiates insert on DB" do
        data[:cost_cents] = "123.12"

        expect(AdvertisementPerformanceLog).not_to receive(:create!)

        entry.insert!
      end
    end

    context "when provided data are valid" do
      let(:attributes) {
        {
          ad_provider: ad_provider,
          brand: brand,
          campaign_name: campaign_name,
          cost_cents: cost_cents,
          start_report_interval: Time.zone.strptime(day, "%d.%m.%Y").beginning_of_day,
          end_report_interval: Time.zone.strptime(day, "%d.%m.%Y").end_of_day,
          adgroup_name: Domain::Cost::AdvertisementPerformanceLog::Importer::Entry::DEFAULT_VALUE,
          creative_name: Domain::Cost::AdvertisementPerformanceLog::Importer::Entry::DEFAULT_VALUE
        }
      }

      it "initiates insert on DB" do
        expect(AdvertisementPerformanceLog).to receive(:create!).with(attributes)

        entry.insert!
      end

      it "creates the record on db" do
        expect { entry.insert! }.to change(AdvertisementPerformanceLog, :count).by(1)
      end
    end
  end
end
