# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::AdvertisementPerformanceLog::Importer::EntriesCollection do
  let(:collection) { described_class.new }
  let(:entry) do
    Domain::Cost::AdvertisementPerformanceLog::Importer::Entry.new(id: 1)
  end

  describe "#add" do
    it "adds the entry to collection" do
      collection.add(entry)

      expect(collection.entries.size).to eq(1)
    end

    context "when trying to add an instance which is not from Entry class" do
      it "throws an error" do
        expect { collection.add(1) }.to raise_error(StandardError)
      end
    end
  end

  describe "#size" do
    before do
      collection.add(entry)
    end

    it "return the correct size of collection" do
      expect(collection.size).to eq(1)
    end
  end

  describe "#insert!" do
    before do
      collection.add(entry)
      allow(entry).to receive(:insert).and_return(true)
    end

    it "initiates the insert at the entries part of collection" do
      expect(entry).to receive(:insert!)

      collection.insert!
    end

    it "return the ids of the entries that not inserted" do
      allow(entry).to receive(:insert).and_return(false)

      ids = collection.insert!

      expect(ids).to eq([entry.id])
    end
  end
end
