# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::AdvertisementPerformanceLog::Importer::Result do
  let(:entries_count) { Faker::Number.number(digits: 4) }
  let(:old_entries_destroyed) { Faker::Number.number(digits: 2) }
  let(:entry_ids_failed_to_insert) { [Faker::Number.number(digits: 3)] }
  let(:result) { described_class.new(entries_count, old_entries_destroyed, entry_ids_failed_to_insert) }

  describe "#message_format" do
    it "return string message" do
      expect(result.message_format).to be_kind_of String
    end

    it "returns string message which is not blank" do
      expect(result.message_format).not_to be_blank
    end
  end
end
