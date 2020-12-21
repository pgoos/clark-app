# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/category/repositories/coverage_features_repository"
require "composites/offers/constituents/category/entities/coverage_feature"
require "composites/utils/repository/errors"

RSpec.describe Offers::Constituents::Category::Repositories::CoverageFeaturesRepository do
  subject { described_class.new }

  describe "#find_by_category_ident", :integration do
    let!(:category) { create(:category_gkv) }

    it "passes scenario" do
      # valid category ident provided
      coverages = subject.find_by_category_ident(category.ident)
      expect(coverages.size).to eq category.coverage_features.size
      expect(coverages.first).to be_kind_of(Offers::Constituents::Category::Entities::CoverageFeature)
      expect(coverages.first).to respond_to(:ident, :name, :value_type)

      # invalid category ident provided
      expect{ subject.find_by_category_ident("invalid-ident") }.to raise_error(Utils::Repository::Errors::Error)
    end
  end
end
