# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::Base do
  before do
    class DummyRecord
      include XlsxImporter::RecordBluePrint

      def validate!
        true
      end
    end

    class DummyCollection
      include XlsxImporter::CollectionBluePrint

      def record_blue_print
        DummyRecord
      end

      def process_successful_entries!; end

      def process_failed_entries!; end
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

  context "#initialize" do
    it "initialize XlsxImporter::Base" do
      object = described_class.new(DummyCollection, file)
      expect(object.instance_variable_get(:@importer)).to be_kind_of(XlsxImporter::Base)
    end
  end

  context "#import!" do
    let(:payment_importer_object) { described_class.new(DummyCollection, file) }

    it "will validate the collection" do
      expect(payment_importer_object.send(:collection)).to receive(:validate!)
      payment_importer_object.import!
    end

    it "will process the collection" do
      expect(payment_importer_object.send(:collection)).to receive(:process!)
      payment_importer_object.import!
    end
  end
end
