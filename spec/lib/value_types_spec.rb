# frozen_string_literal: true

require "value_types"

RSpec.describe ValueTypes do
  it "returns a list of all registered types" do
    expect(ValueTypes.types).to match_array(
      %i[
        AccountingTransactionType
        Boolean
        CallTypes
        Date
        FamilyStatus
        FormOfPayment
        InlandAbroad
        InsuredLossCount
        HouseType
        Int
        MeansOfPayment
        Money
        ProfessionalStatus
        ProfessionalEducationGrade
        Rating
        Text
        KidsCovered
        SpouseCovered
      ]
    )
  end

  it "strips type to the simple type" do
    ValueTypes.types.each do |type|
      expect(ValueTypes.extract_class_object(type).name.demodulize).to eq(type.to_s)
    end
  end

  context "parses hashes to objects" do
    it "returns nil if the type is not a valid ValueObject" do
      expect { ValueTypes.from_hash("something_unknown", {}) }.to raise_error(ArgumentError)
    end

    it "returns nil if not all fields on the value type are filled out" do
      expect(ValueTypes.from_hash("money", value: 100.0)).to eq(nil)
    end

    it "correctly parses a money type" do
      value = ValueTypes.from_hash("money", value: 100.0, currency: "EUR")
      expect(value).to eq(ValueTypes::Money.new(100.0, "EUR"))
    end

    it "correctly parses a text type" do
      value = ValueTypes.from_hash("text", text: "Das ist ein Freitext")
      expect(value).to eq(ValueTypes::Text.new("Das ist ein Freitext"))
    end
  end
end
