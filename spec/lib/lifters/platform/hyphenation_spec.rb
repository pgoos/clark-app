# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::Hyphenation do
  let(:test_string) { "Wir beraten" }
  let(:pass_string) { "Wir bera&shy;ten" }

  let(:testString_two) { "persönliche Bedarfsanalyse" }
  let(:pass_string_two) { "per&shy;sön&shy;li&shy;che Bedarfs&shy;ana&shy;lyse" }

  let(:splitter) { "&shy;" }

  context "converting string to &shy; variant" do
    before do
      described_class::DE.clear_cache!
    end

    it "returns nil for an empty string" do
      expect(described_class.hyphenate("")).to eq("")
    end

    it "applies recursively if an array passed" do
      hyphenated_array = described_class.hyphenate([test_string, testString_two])
      expect(hyphenated_array[0]).to eq(pass_string)
      expect(hyphenated_array[1]).to eq(pass_string_two)
    end

    it "applies recursively with html safeness if an array passed" do
      hyphenated_array = described_class.hyphenate([test_string, testString_two])
      expect(hyphenated_array[0]).to be_html_safe
      expect(hyphenated_array[1]).to be_html_safe
    end

    it "applies recursively if an array passed and allows nil" do
      hyphenated_array = described_class.hyphenate([nil])
      expect(hyphenated_array[0]).to be_nil
    end

    it "applies recursively if an array passed and allows empty strings" do
      hyphenated_array = described_class.hyphenate([""])
      expect(hyphenated_array[0]).to eq("")
    end

    it "applies on a word basis only" do
      expect(described_class.hyphenate(test_string)).to eq(pass_string)
    end

    it "applies on a word basis with the default splitter, if the passed in is an empty string" do
      expect(described_class.hyphenate(test_string, "")).to eq(pass_string)
    end

    it "should return original if value is blank" do
      expect(described_class.hyphenate(nil)).to eq(nil)
    end

    it "should allow to override the splitter" do
      expect(described_class.hyphenate(test_string, "-")).to eq("Wir bera-ten")
    end

    it "should NOT allow ~ as splitter" do
      expect(described_class.hyphenate(test_string, "~")).to eq(pass_string)
    end
  end
end
