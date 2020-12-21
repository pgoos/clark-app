# frozen_string_literal: true

require "rails_helper"

RSpec.describe XlsxImporter::RecordBluePrint do
  before do
    class DummyXlsxRecord
      include XlsxImporter::RecordBluePrint
    end
  end

  let(:params) { {param1: "value1", param2: "value2"} }

  context "#initialize" do
    it "create instance variables with the same params" do
      record_object = DummyXlsxRecord.new(params)
      params.each { |key, value| expect(record_object.instance_variable_get("@#{key}")).to eq(value) }
    end

    it "create getter methods" do
      record_object = DummyXlsxRecord.new(params)
      params.each { |key, value| expect(record_object.send(key)).to eq(value) }
    end
  end

  context "#valid?" do
    it "return if errors has values" do
      record_object = DummyXlsxRecord.new(params)
      record_object.errors = []
      expect(record_object).to be_valid
      record_object.errors = ["some value"]
      expect(record_object).not_to be_valid
    end
  end

  context "#validate!" do
    it "raise NotImplementedError" do
      record_object = DummyXlsxRecord.new(params)
      expect { record_object.validate! }.to raise_error(NotImplementedError)
    end
  end
end
