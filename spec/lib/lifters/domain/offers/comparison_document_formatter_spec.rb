# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Offers::ComparisonDocumentFormatter, type: :helper do
  describe ".format_coverage" do
    it "returns a value by default" do
      coverage_feature = CoverageFeature.new(identifier: "other")
      coverage = described_class.format_coverage("FOO", coverage_feature)
      expect(coverage).to eq "FOO"
    end

    context "when value is '-1'" do
      it "returns undefined for certain categories" do
        coverage_feature = CoverageFeature.new(identifier: "int_slndsfnthltnnrhlbrp_af1614")
        coverage = described_class.format_coverage(ValueTypes::Int.new("-1"), coverage_feature)
        expect(coverage).to eq "unbegrenzt"

        coverage_feature = CoverageFeature.new(identifier: "int_slndsfnthltrhlbrp_590e50")
        coverage = described_class.format_coverage(ValueTypes::Int.new("-1"), coverage_feature)
        expect(coverage).to eq "unbegrenzt"

        coverage_feature = CoverageFeature.new(identifier: "other")
        coverage = described_class.format_coverage(ValueTypes::Int.new("-1"), coverage_feature)
        expect(coverage).to eq "-1"
      end
    end

    context "when coverage relates to staying abroad period" do
      it "inserts a unit" do
        coverage_feature = CoverageFeature.new(identifier: "int_slndsfnthltnnrhlbrp_af1614")
        coverage = described_class.format_coverage(ValueTypes::Int.new("1"), coverage_feature)
        expect(coverage).to eq "1 Monat"

        coverage_feature = CoverageFeature.new(identifier: "int_slndsfnthltrhlbrp_590e50")
        coverage = described_class.format_coverage(ValueTypes::Int.new("2"), coverage_feature)
        expect(coverage).to eq "2 Monate"
      end
    end

    context "when coverage is co-insurance of sailboat" do
      it "inserts a unit" do
        coverage_feature = CoverageFeature.new(identifier: "int_mtvrschrnggnrsglbt_a6531b")
        coverage = described_class.format_coverage(ValueTypes::Int.new("100"), coverage_feature)
        expect(coverage).to eq "bis 100 qm"
      end
    end

    context "when coverage is co-insurance of motorboat" do
      it "inserts a unit" do
        coverage_feature = CoverageFeature.new(identifier: "int_mtvrschrnggnrmtrbt_75927e")
        coverage = described_class.format_coverage(ValueTypes::Int.new("100"), coverage_feature)
        expect(coverage).to eq "bis 100 PS"
      end
    end

    context "when coverage is co-insurance of undeveloped land" do
      it "inserts a unit" do
        coverage_feature = CoverageFeature.new(identifier: "int_mtvrschrngnbbtgrndstck_e66184")
        coverage = described_class.format_coverage(ValueTypes::Int.new("100"), coverage_feature)
        expect(coverage).to eq "bis 100 qm"
      end
    end
  end
end
