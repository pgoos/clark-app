# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Estimations::Products::Guaranteed do
  subject { described_class.new(retirement_product) }

  describe "#to_i" do
    let(:category) { build :category }
    let(:mandate)  { build :mandate, birthdate: Date.parse("1/1/1985") }
    let(:product)  { build :product, :shallow, mandate: mandate, category: category }

    let(:retirement_product) do
      build :retirement_product,
            guaranteed_pension_continueed_payment_cents: 105_651,
            guaranteed_capital_cents: 25_000,
            product: product,
            retirement_factor_cents: 3416,
            pension_capital_today_cents: 15_300
    end

    context "when CATEGORY_IDENT_STATE" do
      before do
        allow(retirement_product).to receive(:category).and_return("gesetzliche_rentenversicherung")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when DIREKTVERSICHERUNG_CLASSIC" do
      before do
        allow(retirement_product).to receive(:category).and_return("direktversicherung_classic")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when PRIVATE_RENTENVERSICHERUNG" do
      before do
        allow(retirement_product).to receive(:category).and_return("private_rentenversicherung")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when RIESTER_CLASSIC" do
      before do
        allow(retirement_product).to receive(:category).and_return("riester_classic")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when BASIS_CLASSIC" do
      before do
        allow(retirement_product).to receive(:category).and_return("basis_classic")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when DIREKTVERSICHERUNG_FONDS" do
      before do
        allow(retirement_product).to receive(:category).and_return("direktversicherung_fonds")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when PRIVATRENTE_FONDS" do
      before do
        allow(retirement_product).to receive(:category).and_return("privatrente_fonds")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when RIESTER_FONDS" do
      before do
        allow(retirement_product).to receive(:category).and_return :riester_fonds
      end

      it { expect(subject.to_i).to eq 105_651 }

      context "with empty retirement_three_percent_growth_cents" do
        before do
          allow(retirement_product).to receive(:retirement_three_percent_growth_cents).and_return nil
        end

        it { expect(subject.to_i).to eq 105_651.0 }
      end
    end

    context "when BASIS_FONDS" do
      before do
        allow(retirement_product).to receive(:category).and_return :basis_fonds
      end

      it { expect(subject.to_i).to eq 105_651 }

      context "with empty retirement_three_percent_growth_cents" do
        before do
          allow(retirement_product).to receive(:retirement_three_percent_growth_cents).and_return nil
        end

        it { expect(subject.to_i).to eq 105_651.0 }
      end
    end

    context "when PENSIONSKASSE" do
      before do
        allow(retirement_product).to receive(:category).and_return("pensionskasse")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when UNTERSTUETZUNGSKASSE" do
      before do
        allow(retirement_product).to receive(:category).and_return("unterstuetzungskasse")
      end

      it { expect(subject.to_i).to eq 105_651 }
    end

    context "when KAPITALLEBENSVERSICHERUNG" do
      before { allow(retirement_product).to receive(:category).and_return :kapitallebensversicherung }

      it "calls spicific formula" do
        expect(subject.to_i).to eq 68
      end
    end

    context "when CATEGORY_IDENT_DIREKTZUSAGE" do
      before do
        allow(retirement_product).to receive(:category).and_return :direktzusage
      end

      it { expect(subject.to_i).to eq 8 }
    end

    context "when CATEGORY_IDENT_RIESTER_FONDS_NON_INSURANCE" do
      before do
        allow(retirement_product).to receive(:category).and_return :riester_fonds_non_insurance
      end

      it { expect { subject.to_i }.to raise_error(NotImplementedError) }
    end
  end
end
