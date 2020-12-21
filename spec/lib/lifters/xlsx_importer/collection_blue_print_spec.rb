# frozen_string_literal: true

require "rails_helper"

RSpec.describe XlsxImporter::CollectionBluePrint do
  before do
    class DummyXlsxCollection
      include XlsxImporter::CollectionBluePrint
    end
  end

  let(:params) { %w[col1 col3] }
  let(:mapping_hash) { {"col1" => :param1, "col4" => :param4} }

  context "#initialize" do
    it "success to extract param_list when mapping_hash passed" do
      collection_object = DummyXlsxCollection.new(params, mapping_hash)
      expect(collection_object.instance_variable_get(:@param_list)).to eq([:param1, nil])
    end

    it "param_list contains nil values if no mapping_hash passed" do
      collection_object = DummyXlsxCollection.new(params)
      expect(collection_object.instance_variable_get(:@param_list)).to eq([nil, nil])
    end

    it "successfully initialized" do
      collection_object = DummyXlsxCollection.new(params, mapping_hash)
      expect(collection_object.instance_variable_get(:@param_list)).not_to be_nil
      expect(collection_object.instance_variable_get(:@records)).to eq([])
      expect(collection_object.instance_variable_get(:@failed_entries)).to eq([])
      expect(collection_object.instance_variable_get(:@successful_entries)).to eq([])
    end
  end

  context "#push" do
    let(:values) { [1, 2] }

    it "raise NotImplementedError" do
      collection_object = DummyXlsxCollection.new(params, mapping_hash)
      expect { collection_object.push(values) }.to raise_error(NotImplementedError)
    end
  end

  context "#process!" do
    it "raise NotImplementedError" do
      collection_object = DummyXlsxCollection.new(params, mapping_hash)
      expect { collection_object.process! }.to raise_error(NotImplementedError)
    end
  end

  context "#validate!" do
    before do
      class SuperDummyRecord
        def validate!
          true
        end

        def valid?
          @valid
        end
      end
    end

    it "validate each record" do
      collection_object = DummyXlsxCollection.new(params, mapping_hash)
      records = [SuperDummyRecord.new, SuperDummyRecord.new]
      collection_object.instance_variable_set(:@records, records)
      expect(records).to all(receive(:validate!))
      collection_object.validate!
    end

    it "partition records into @successful_entries and @failed_entries" do
      collection_object = DummyXlsxCollection.new(params, mapping_hash)
      records = [SuperDummyRecord.new, SuperDummyRecord.new]
      records[0].instance_variable_set(:@valid, false)
      records[1].instance_variable_set(:@valid, true)
      collection_object.instance_variable_set(:@records, records)
      collection_object.validate!
      expect(collection_object.instance_variable_get(:@successful_entries)).to eq(Array(records[1]))
      expect(collection_object.instance_variable_get(:@failed_entries)).to eq(Array(records[0]))
    end
  end
end
