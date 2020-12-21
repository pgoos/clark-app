# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::AdvertisementPerformanceLog::Importer::Base do
  let(:starting_from) { Faker::Date.between(from: 2.months.ago, to: Date.today - 1.month).strftime("%Y-%m-%d") }
  let(:ending_at) { Faker::Date.between(from: 1.months.ago, to: Date.today).strftime("%Y-%m-%d") }
  let(:ad_provider) { Faker::Lorem.words(number: 1).join("") }
  let(:brand) { true }
  let(:csv_file) {
    fixture_file_upload(Rails.root.join("spec/fixtures/files/advertisement_performance_logs/cost_sample.csv"),
                        "text/csv")
  }
  let(:admin) { create(:admin) }
  let(:document) { Platform::FileUpload.persist_file(csv_file, admin, DocumentType.csv) }

  describe "#import!" do
    let!(:importer) { described_class.new(document.id, starting_from, ending_at, ad_provider, brand) }

    it "destroys old records" do
      create(
        :advertisement_performance_log,
        ad_provider: ad_provider,
        end_report_interval: Date.parse(ending_at, "%Y-%m-%d"),
        brand: true
      )

      allow_any_instance_of(Domain::Cost::AdvertisementPerformanceLog::Importer::Parser::CSV)
        .to receive(:parse_entries_collection)
        .and_return(Domain::Cost::AdvertisementPerformanceLog::Importer::EntriesCollection.new)

      expect { importer.import! }.to change(::AdvertisementPerformanceLog, :count).by(-1)
    end

    it "return instance of Result" do
      expect(importer.import!).to be_kind_of(Domain::Cost::AdvertisementPerformanceLog::Importer::Result)
    end

    it "inserts entries in database" do
      # This count is affected directly if change the sample csv file that we have
      expect { importer.import! }.to change(::AdvertisementPerformanceLog, :count).by(2)
    end

    it "destroys the document after finishes the import" do
      expect { importer.import! }.to change(Document, :count).by(-1)
    end
  end
end
