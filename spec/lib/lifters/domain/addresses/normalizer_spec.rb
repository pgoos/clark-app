# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Addresses::Normalizer do
  describe ".same_address?" do
    [
      ["Goethestraße", "goethestraße", true],
      ["Goethestraße", "Goethestrasse", true],
      ["Goethestraße", "Goethestr.", true],
      ["Goethestraße", "Goethestraße ", true],
      ["Goethestraße", " Goethestraße ", true],
      ["Goethestraße verwachsene", "Goethestraße Verwachsene", true],
      ["Goethestraße wiesauer", "Goethestraße Wiesauer ", true],
      ["Goethestraße den ", "Goethestraße Den ", true],
      ["Goethestraße der Strasse", "Goethestraße der strasse", true],
      ["Den Goethestraße", "den goethestraße", true],
      ["Goethestraße de Goethe-straße", "Goethestraße de Goethe-straße", true]
    ].each do |test|
      context "street1 =e #{test[0]} and street2 = #{test[1]}" do
        let(:address) { build(:address, street: test[0]) }
        let(:address_attrs) { attributes_for(:address, street: test[1]) }

        it "returns #{test[2]}" do
          expect(described_class.same_address?(address, address_attrs)).to eq(test[2])
        end
      end
    end
  end
end
