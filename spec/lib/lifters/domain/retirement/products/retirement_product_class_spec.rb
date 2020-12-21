# frozen_string_literal: true

require "rails_helper"

describe Domain::Retirement::Products::RetirementProductClass do
  describe ".by_category" do
    subject { described_class.by_category category }

    context "when category belongs to personal pilar" do
      let(:category) { build_stubbed :category, ident: "f0a0e78c" }

      it { is_expected.to eq Retirement::PersonalProduct }
    end

    context "when category belongs to corporate pilar" do
      let(:category) { build_stubbed :category, ident: "e97a99d7" }

      it { is_expected.to eq Retirement::CorporateProduct }
    end

    context "when category belongs to equity pilar" do
      let(:category) { build_stubbed :category, ident: "1fc11bd4" }

      it { is_expected.to eq Retirement::EquityProduct }
    end

    context "when category belongs to state pilar" do
      let(:category) { build_stubbed :category, ident: "84a5fba0" }

      it { is_expected.to eq Retirement::StateProduct }
    end

    context "when category does not belong to any pilar" do
      let(:category) { build_stubbed :category, ident: "foo" }

      it { is_expected.to eq nil }
    end

    context "with combo categories" do
      let(:category) { build_stubbed :category, :combo }

      before { allow(category).to receive(:included_categories).and_return included_categories }

      context "when none of included categories relate to retirement pilars" do
        let(:included_categories) { [build_stubbed(:category)] }

        it { is_expected.to eq nil }
      end

      context "when category has more than one included retirement categories" do
        let(:included_categories) do
          [
            build_stubbed(:category, ident: "e97a99d7"),
            build_stubbed(:category, ident: "84a5fba0")
          ]
        end

        it "raises an exception" do
          expect { subject }.to raise_error described_class::RetirementTypeConflict
        end
      end

      context "when category has included retirement categories" do
        let(:included_categories) do
          [
            build_stubbed(:category),
            build_stubbed(:category, ident: "84a5fba0")
          ]
        end

        it "returns class based on included category pilar" do
          expect(subject).to eq Retirement::StateProduct
        end
      end
    end
  end
end
