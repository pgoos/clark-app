# frozen_string_literal: true

require "rails_helper"

describe AbTesting::PageVariations do
  describe "#enabled?" do
    it "returns true if settings is turned on" do
      page = object_double(
        Comfy::Cms::Page.new,
        fragments_attributes: [
          {identifier: "ab-testing.experiment_on", content: true}
        ]
      )
      expect(described_class.new(page)).to be_enabled
    end

    it "returns false if settings is turned off" do
      page = object_double(
        Comfy::Cms::Page.new,
        fragments_attributes: [
          {identifier: "ab-testing.experiment_on", content: false}
        ]
      )
      expect(described_class.new(page)).not_to be_enabled
    end

    it "returns false if setting is blank" do
      page = object_double Comfy::Cms::Page.new, fragments_attributes: [{}]
      expect(described_class.new(page)).not_to be_enabled
    end
  end

  describe "#all" do
    let(:page) do
      object_double Comfy::Cms::Page.new, full_path: "PAGE_URL", fragments_attributes: blocks
    end

    let(:blocks) do
      [
        {identifier: "FOO", content: "BAR"},
        {identifier: "ab-testing.variation1_name", content: "VAR1_NAME"},
        {identifier: "ab-testing.variation1_url",  content: "VAR1_URL"},
        {identifier: "ab-testing.variation2_name", content: "VAR2_NAME"},
        {identifier: "ab-testing.variation2_url",  content: "VAR2_URL"},
        {identifier: "ab-testing.variation3_name", content: "VAR3_NAME"},
        {identifier: "ab-testing.variation3_url",  content: "VAR3_URL"}
      ]
    end

    describe "#all" do
      it "returns normalized array of variations" do
        expect(described_class.new(page).all).to match_array \
          [
            {name: "VAR1_NAME", url: "VAR1_URL"},
            {name: "VAR2_NAME", url: "VAR2_URL"},
            {name: "VAR3_NAME", url: "VAR3_URL"},
            {name: :control,    url: "PAGE_URL"}
          ]
      end
    end

    describe "#random" do
      it "returns random variation" do
        variations = []
        page_variations = described_class.new(page)

        allow(page_variations).to receive(:all).and_return(variations)
        allow(variations).to receive(:sample).and_return(name: "FOO_VAR")

        expect(page_variations.random).to eq(name: "FOO_VAR")
      end
    end
  end
end
