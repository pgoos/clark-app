# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::AdvertisementPerformanceLog::Importer::Parser::CSV do
  let(:ad_provider) { Faker::Lorem.words(number: 1) }
  let(:brand) { true }
  let(:csv_file) { double(open: StringIO.new(sample_csv_content)) }
  let(:parser) { described_class.new(csv_file, ad_provider, brand) }
  let(:campaign_name) { Faker::Lorem.words(number: 2).join(" ") }
  let(:cost_cents) { Faker::Number.number(digits: 4) }
  let(:day) { Faker::Date.between(from: 1.year.ago, to: Date.today).strftime("%d.%m.%Y") }

  describe "#parse_entries_collection" do
    let(:entries_collection) { parser.parse_entries_collection }

    it "returns an entries collection" do
      expect(entries_collection)
        .to be_kind_of Domain::Cost::AdvertisementPerformanceLog::Importer::EntriesCollection
    end

    it "returns collection with all the entries inside the file" do
      expect(entries_collection.size).to eq(2)
    end

    it "parses the id correctly to entry" do
      expect(entries_collection.entries[0].id).to eq(1)
    end

    it "parses campaign_name correctly to entry" do
      expect(entries_collection.entries[0].campaign_name).to eq(campaign_name)
    end

    it "parses cost_cents correctly to entry" do
      expect(entries_collection.entries[0].cost_cents).to eq(cost_cents.to_s)
    end

    it "parses day correctly to entry" do
      expect(entries_collection.entries[0].day).to eq(day)
    end

    it "parses brand correctly to entry" do
      expect(entries_collection.entries[0].brand).to eq(brand)
    end

    it "parses ad_provider correctly to entry" do
      expect(entries_collection.entries[0].ad_provider).to eq(ad_provider)
    end
  end

  def sample_csv_content
    <<~CSV_CONTENT
      campaign_name,day,cost_cents
      #{campaign_name},#{day},#{cost_cents}
      #{Faker::Lorem.words(number: 2).join(' ')},#{Faker::Date.forward(days: 30)},#{Faker::Number.number(digits: 4)}
    CSV_CONTENT
  end
end
