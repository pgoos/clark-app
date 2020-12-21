# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::CsvBuilder do
  let!(:expected_csv) do
    <<~CSV
      First Heading,Second Heading
      First Row,Second Row
    CSV
  end

  context "when correct number of element in rows are present" do
    it "returns the csv as expected" do
      csv_builder = described_class.new(["First Heading", "Second Heading"])
      csv_builder.add_row(["First Row", "Second Row"])
      expect(csv_builder.csv).to eq(expected_csv)
    end
  end

  context "when the elements in the row dont match the number of columns as defined by the headings" do
    it "doesnt append the csv" do
      csv_builder = described_class.new(["First Heading", "Second Heading"])
      csv_builder.add_row(["First Row", "Second Row"])
      csv_builder.add_row(["something"])
      expect(csv_builder.csv).to eq(expected_csv)
    end
  end

  context "when the row is nil" do
    it "does not append to the csv" do
      csv_builder = described_class.new(["First Heading", "Second Heading"])
      csv_builder.add_row(["First Row", "Second Row"])
      csv_builder.add_row(nil)
      expect(csv_builder.csv).to eq(expected_csv)
    end

    it "continues appending even after it gets nil in previous row" do
      csv_builder = described_class.new(["First Heading", "Second Heading"])
      csv_builder.add_row(["First Row", "Second Row"])
      csv_builder.add_row(["something"])
      csv_builder.add_row(["First Row", "Second Row"])
      csv_builder.add_row(nil)
      csv_builder.add_row(nil)
      csv_builder.add_row(["First Row", "Second Row"])
      expect(csv_builder.csv).not_to eq(expected_csv)
    end
  end
end
