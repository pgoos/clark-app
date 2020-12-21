# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::InsuredPersons do
  subject { described_class }

  let(:product) { build_stubbed :product, :shallow, plan: plan, coverages: coverages }
  let(:plan) { build_stubbed :plan, :shallow, category: category }
  let(:category) { build_stubbed :category, coverage_features: coverage_features }

  context "using identifier" do
    let(:coverage_features) do
      [
        build(
          :coverage_feature,
          identifier: CoverageFeature::COINSURANCE_KIDS_IDENT,
          value_type: "Boolean"
        ),
        build(
          :coverage_feature,
          identifier: CoverageFeature::COINSURANCE_SPOUSE_IDENT,
          value_type: "Boolean"
        )
      ]
    end

    context "when neither kids nor spouse are included into insurance" do
      let(:coverages) do
        {
          CoverageFeature::COINSURANCE_KIDS_IDENT => {"value" => "FALSE"},
          CoverageFeature::COINSURANCE_SPOUSE_IDENT => {"value" => "FALSE"}
        }
      end

      it { expect(subject.(product)).to eq :applicant }
    end

    context "when kids are included into insurance" do
      let(:coverages) do
        {
          CoverageFeature::COINSURANCE_KIDS_IDENT => {"value" => "TRUE"},
          CoverageFeature::COINSURANCE_SPOUSE_IDENT => {"value" => "FALSE"}
        }
      end

      it { expect(subject.(product)).to eq :family }
    end

    context "when spouse is included into insurance" do
      let(:coverages) do
        {
          CoverageFeature::COINSURANCE_KIDS_IDENT => {"value" => "FALSE"},
          CoverageFeature::COINSURANCE_SPOUSE_IDENT => {"value" => "TRUE"}
        }
      end

      it { expect(subject.(product)).to eq :family }
    end
  end

  context "using value type" do
    let(:coverage_features) do
      [
        build(
          :coverage_feature,
          identifier: "ident1",
          value_type: "KidsCovered"
        ),
        build(
          :coverage_feature,
          identifier: "ident2",
          value_type: "SpouseCovered"
        )
      ]
    end

    context "when neither kids nor spouse are included into insurance" do
      let(:coverages) do
        {
          "ident1" => {"value" => "FALSE"},
          "ident2" => {"value" => "FALSE"}
        }
      end

      it { expect(subject.(product)).to eq :applicant }
    end

    context "when kids are included into insurance" do
      let(:coverages) do
        {
          "ident1" => {"value" => "TRUE"},
          "ident2" => {"value" => "FALSE"}
        }
      end

      it { expect(subject.(product)).to eq :family }
    end

    context "when spouse is included into insurance" do
      let(:coverages) do
        {
          "ident1" => {"value" => "FALSE"},
          "ident2" => {"value" => "TRUE"}
        }
      end

      it { expect(subject.(product)).to eq :family }
    end
  end
end
