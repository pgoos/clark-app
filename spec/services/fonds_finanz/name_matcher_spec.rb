# frozen_string_literal: true

require "rails_helper"

RSpec.describe FondsFinanz::NameMatcher do
  before do
    class DummyNameMatcher
      include FondsFinanz::NameMatcher
    end
  end

  def operand_maker(first_name, last_name)
    OpenStruct.new(first_name: first_name, last_name: last_name)
  end

  let(:dummy_object) { DummyNameMatcher.new }
  let(:operand2) { operand_maker("Thommy", "Kathert") }

  context "#same_name?" do
    context "return true in case of name matches" do
      it "match when different case letters" do
        expect(dummy_object).to be_same_name(operand_maker("thommy", "kathert"), operand_maker("THOMMY", "KATHERT"))
      end

      it "match when one of names include the other" do
        expect(dummy_object).to be_same_name(operand_maker("Thommy Iturbe", "Kathert"), operand2)
        expect(dummy_object).to be_same_name(operand_maker("Thommy Iturbe", "Kathert"),
                                             operand_maker("Iturbe", "Kathert"))
        expect(dummy_object).to be_same_name(operand_maker("Thommy", "Kathert Iturbe"), operand2)
        expect(dummy_object).to be_same_name(operand_maker("Thommy", "Kathert Iturbe"),
                                             operand_maker("Thommy", "Iturbe"))
      end

      it "match when extra spaces found" do
        expect(dummy_object).to be_same_name(operand_maker("Thommy   ", "Kathert"), operand2)
        expect(dummy_object).to be_same_name(operand_maker("  Thommy", "Kathert"), operand2)
        expect(dummy_object).to be_same_name(operand_maker("Thommy", "   Kathert"), operand2)
        expect(dummy_object).to be_same_name(operand_maker("Thommy", "Kathert   "), operand2)
      end

      it "match when diacritics found" do
        expect(dummy_object).to be_same_name(operand_maker("Thommy", "Heß"), operand_maker("Thommy", "Hess"))
        expect(dummy_object).to be_same_name(operand_maker("Thommy", "Müller"), operand_maker("Thommy", "Mueller"))
      end

      it "match when title found" do
        expect(dummy_object).to be_same_name(operand_maker("Dr. Thommy", "Kathert"), operand2)
        expect(dummy_object).to be_same_name(operand_maker("Thommy", "Müller"), operand_maker("Dr Thommy", "Müller"))
      end

      it "match when first name only a shortcut" do
        expect(dummy_object).to be_same_name(operand_maker("T.", "Kathert"), operand2)
        expect(dummy_object).not_to be_same_name(operand_maker("Thommy", "M."), operand2)
      end
    end
  end
end
