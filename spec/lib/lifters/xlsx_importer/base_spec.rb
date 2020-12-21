# frozen_string_literal: true

require "rails_helper"

RSpec.describe XlsxImporter::Base do
  before do
    class TestRecord
      include XlsxImporter::RecordBluePrint

      def validate!
        @valid = col4.present?
      end
    end

    class TestCollection
      include XlsxImporter::CollectionBluePrint

      MAPPING_HASH = {
        "col1" => :col1,
        "col2" => :col2,
        "col3" => :col3,
        "col4" => :col4
      }.freeze

      def initialize(params)
        super(params, MAPPING_HASH)
      end

      def record_blue_print
        TestRecord
      end
    end
    allow(SimpleXlsxReader).to receive(:open).with(any_args).and_return(file)
  end

  let(:file) {
    OpenStruct.new(sheets:
                     [OpenStruct.new(rows:
                                       [%w[col1 col2 col3 col4],
                                        [1, "something", 2.3, nil],
                                        [2, "something else", 4.5, "valid value"]])])
  }
  let(:collection) { described_class.new(TestCollection, file).collection }

  context "#collection" do
    let(:records) { collection.instance_variable_get(:@records) }

    context "#records" do
      it "have the same value as in file" do
        data_rows = file.sheets.first.rows[1..-1]
        expect(records.map(&:col1)).to eq(data_rows.map(&:first))
        expect(records.map(&:col2)).to eq(data_rows.map(&:second))
        expect(records.map(&:col3)).to eq(data_rows.map(&:third))
        expect(records.map(&:col4)).to eq(data_rows.map(&:fourth))
      end
    end

    it "have same number of records as in file" do
      expect(collection.instance_variable_get(:@records).size).to eq(file.sheets.first.rows.size - 1)
    end

    it "partition records correctly after validation" do
      expect(collection.instance_variable_get(:@successful_entries)).to eq([])
      expect(collection.instance_variable_get(:@failed_entries)).to eq([])
      collection.validate!
      expect(collection.instance_variable_get(:@successful_entries)).to eq(records.select(&:valid?))
      expect(collection.instance_variable_get(:@failed_entries)).to eq(records.reject(&:valid?))
    end

    it "call process_successful_entries!" do
      expect(collection).to receive(:process_successful_entries!)
      expect(collection).to receive(:process_failed_entries!)
      collection.process!
    end
  end
end
