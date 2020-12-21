# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/category/interactors/find_coverage_features"

RSpec.describe Offers::Constituents::Category::Interactors::FindCoverageFeatures do
  context "invalid category_ident provided" do
    it "returns error" do
      result = described_class.new.call("fake-ident")
      expect(result).not_to be_success
      expect(result.errors).not_to be_empty
    end
  end

  context "with valid category_ident" do
    let(:coverages) { double(:coverages) }
    let(:category_ident) { "12345678" }

    it "exposes coverage_features" do
      expect_any_instance_of(
        Offers::Constituents::Category::Repositories::CoverageFeaturesRepository
      ).to receive(:find_by_category_ident).with(category_ident).and_return(coverages)

      expect(described_class.new.call(category_ident).coverage_features).to eq coverages
    end
  end
end
