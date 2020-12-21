# frozen_string_literal: true

require "spec_helper"

require "value_types/int"
require "value_types/transformers"

RSpec.describe ValueTypes::Transformers do
  let(:expected_value) { described_class.call(type, value) }

  describe "default transformer" do
    let(:type) { "Not mapped" }

    context "when value type is not mapped in transforme" do
      let(:value) { Object.new  }

      it "returns the values of to_s" do
        expect(expected_value).to eq(value.to_s)
      end
    end
  end

  describe "Int transformer" do
    let(:type) { "Int" }

    context "when value is -1" do
      let(:value) { ValueTypes::Int.new(-1) }

      it "returns unbegrenzt" do
        expect(expected_value).to eq("unbegrenzt")
      end
    end

    describe "with invalid value" do
      context "when value type is nil" do
        let(:value) { nil }

        it "returns unwichtig" do
          expect(expected_value).to eq("unwichtig")
        end
      end

      context "when wrapped value is nil" do
        let(:value) { ValueTypes::Int.new(nil) }

        it "returns unwichtig" do
          expect(expected_value).to eq("unwichtig")
        end
      end
    end

    context "when value is a correct one" do
      let(:value) { ValueTypes::Int.new(5) }

      it "returns the value as string" do
        expect(expected_value).to eq("5")
      end
    end
  end
end
