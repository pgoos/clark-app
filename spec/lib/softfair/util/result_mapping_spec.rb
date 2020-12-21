# frozen_string_literal: true

require "rails_helper"
require "softfair/util/result_mapping"

RSpec.describe Softfair::Util::ResultMapping do
  subject do
    class ResultMappingDummy
      include Softfair::Util::ResultMapping
    end
    ResultMappingDummy.new
  end

  context "generic_mapping" do
    let(:to_be_applied_method) do
      lambda { |value| value.to_s }
    end

    it "applies the passed helper method to the value param" do
      expect(subject.generic_mapping(1, to_be_applied_method)).to eq('1')
    end

    it "applies the helper method on the first element of an array if an array of values is passed as param" do
      expect(subject.generic_mapping([1,2], to_be_applied_method)).to eq('1')
    end
  end

  context "map_boolean" do
    it "returns the true value type if true value is passed as a param" do
      expect(subject.map_boolean("true")).to eq(ValueTypes::Boolean::TRUE)
    end

    it "returns the false value type if false value is passed as a param" do
      expect(subject.map_boolean("true")).to eq(ValueTypes::Boolean::TRUE)
    end

    it "returns the false value type if empty value is passed as a param" do
      expect(subject.map_boolean('')).to eq(ValueTypes::Boolean::FALSE)
    end

    it "returns the true value type if an array containing true value is passed as a param" do
      expect(subject.map_boolean(["true"])).to eq(ValueTypes::Boolean::TRUE)
    end
  end

  context "map_money" do
    it "returns the corresponding money value type if value is passed as a param" do
      expect(subject.map_money("50")).to eq(ValueTypes::Money.new(50, "EUR"))
    end

    it "returns 0 money value type if non integer value is passed as a param" do
      expect(subject.map_money("not money")).to eq(ValueTypes::Money.new(0, "EUR"))
    end

    it "returns the 0 money value type if empty value is passed as a param" do
      expect(subject.map_money('')).to eq(ValueTypes::Money.new(0, "EUR"))
    end

    it "returns the corresponding value type if an array containing money value is passed as a param" do
      expect(subject.map_money(["50"])).to eq(ValueTypes::Money.new(50, "EUR"))
    end
  end

  context "nested_hash_value" do
    let(:element_name) { "name_#{rand}" }

    it "returns an empty array for no result" do
      expect(subject.nested_hash_value({}, element_name)).to be_empty
    end

    it "returns an array with one item for one item" do
      hash = { element_name => :element1 }
      expect(subject.nested_hash_value(hash, element_name)).to match_array([:element1])
    end

    it "returns an array with the items, if there are more than one" do
      hash = { element_name => [:element1, :element2] }
      expect(subject.nested_hash_value(hash, element_name)).to match_array([:element1, :element2])
    end

    it "searches the child hashes" do
      hash = { "some_key" => { element_name => :element1 }}
      expect(subject.nested_hash_value(hash, element_name)).to match_array([:element1])
    end

    it "searches the child arrays" do
      hash = { "some_key" => [{ element_name => :element1 }]}
      expect(subject.nested_hash_value(hash, element_name)).to match_array([:element1])
    end

    it "searches child elements, if not the first elements" do
      hash = {
        "some_key"  => {element_name => :element1},
        "some_key2" => [{element_name => :element2}]
      }
      expect(subject.nested_hash_value(hash, element_name)).to match_array([:element1, :element2])
    end
  end
end
