# frozen_string_literal: true

require 'category_coverage_features_fix'

require "rails_helper"

RSpec.describe CategoryCoverageFeaturesFix do
  let(:rs) { CategoryCoverageFeaturesFix.new(RechtsschutzValues) }
  let(:phv) { CategoryCoverageFeaturesFix.new(PhvValues) }

  it "compare text values rs" do
    expect(rs.same_data).to be_truthy
  end

  it "compare text values phv" do
    expect(phv.same_data).to be_truthy
  end

  it "creates the map rs" do
    map = rs.build_map

    found_same_values = map.select do |key, value|
      key == value
    end.any?
    expect(found_same_values).to be_falsey
  end

  it "creates the map phv" do
    map = phv.build_map

    found_same_values = map.select do |key, value|
      key == value
    end.any?
    expect(found_same_values).to be_falsey
  end

  it "writes the old coverage features to the category rs" do
    create(:category, id: 20, coverage_features: RechtsschutzValues.wrong_new)

    rs.write_to_category

    rs_category = Category.find(20)

    expect(rs_category.coverage_features.size).not_to eq(0)
    old_values = RechtsschutzValues.old.map(&:symbolize_keys)
    rs_category.coverage_features.each_with_index do |cf, index|
      raise "not a coverage feature" unless cf.is_a?(CoverageFeature)
      expect(cf.identifier).to eq(old_values[index][:identifier])
    end
  end

  it "writes the old coverage features to the category phv" do
    create(:category, id: 10, coverage_features: PhvValues.wrong_new)

    phv.write_to_category

    phv_category = Category.find(10)

    expect(phv_category.coverage_features.size).not_to eq(0)
    old_values = PhvValues.old.map(&:symbolize_keys)
    phv_category.coverage_features.each_with_index do |cf, index|
      raise "not a coverage feature" unless cf.is_a?(CoverageFeature)
      expect(cf.identifier).to eq(old_values[index][:identifier])
    end
  end
end
