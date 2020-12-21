# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Estimations::Products::Surplus do
  subject { described_class.new(retirement_product) }

  let(:category) { build :category }
  let(:mandate)  { build :mandate, birthdate: Date.parse("1/1/1985") }
  let(:product)  { build :product, :shallow, mandate: mandate, category: category }

  let(:retirement_product) do
    build :retirement_product,
          surplus_retirement_income_cents: 500,
          retirement_three_percent_growth_cents: 10_000,
          fund_capital_three_percent_growth_cents: 693_800,
          possible_capital_including_surplus_cents: 25_000,
          retirement_factor_cents: 3416,
          product: product
  end

  context "when PRIVATE_RENTENVERSICHERUNG" do
    before { allow(retirement_product).to receive(:category).and_return :private_rentenversicherung }

    it { expect(subject.to_i).to eq 500 }
  end

  context "when RIESTER_CLASSIC" do
    before { allow(retirement_product).to receive(:category).and_return :riester_classic }

    it { expect(subject.to_i).to eq 500 }
  end

  context "when BASIS_CLASSIC" do
    before { allow(retirement_product).to receive(:category).and_return :basis_classic }

    it { expect(subject.to_i).to eq 500 }
  end

  context "when DIREKTVERSICHERUNG_CLASSIC" do
    before { allow(retirement_product).to receive(:category).and_return :direktversicherung_classic }

    it { expect(subject.to_i).to eq 500 }
  end

  context "when DIREKTVERSICHERUNG_FONDS" do
    before { allow(retirement_product).to receive(:category).and_return :direktversicherung_fonds }

    it { expect(subject.to_i).to eq 10_000 }
  end

  context "when PENSIONSKASSE" do
    before { allow(retirement_product).to receive(:category).and_return :pensionskasse }

    it { expect(subject.to_i).to eq 500 }
  end

  context "when UNTERSTUETZUNGSKASSE" do
    before { allow(retirement_product).to receive(:category).and_return :unterstuetzungskasse }

    it { expect(subject.to_i).to eq 500 }
  end

  context "when GESETZLICHE_RENTENVERSICHERUNG" do
    let(:situation)      { instance_double(Domain::Situations::RetirementSituation) }
    let(:initial_income) { instance_double(Domain::Retirement::Estimations::InitialIncome::Gross) }

    before { allow(retirement_product).to receive(:category).and_return :gesetzliche_rentenversicherung }

    context "when forecast is document/customer" do
      before do
        allow(retirement_product).to receive(:forecast).and_return :document
        allow(retirement_product).to receive(:initial?).and_return(false)
      end

      it { expect(subject.to_i).to eq 500 }
    end

    context "when not ready for calculation" do
      before do
        allow(Domain::Situations::RetirementSituation).to receive(:new).and_return(situation)
        allow(situation).to receive(:yearly_gross_income_cents).and_return(40_000 * 100)

        allow(Domain::Retirement::Estimations::InitialIncome::Gross).to receive(:new).and_return(initial_income)
        allow(initial_income).to receive(:call).and_return(1000)
      end

      context "when forecast is initial" do
        let(:retirement_product) do
          build_stubbed(:retirement_state_product, forecast: :initial, surplus_retirement_income_cents: 100)
        end

        it { expect(subject.to_i).to eq 1000 }
      end

      context "when surpluss is zero" do
        let(:retirement_product) do
          build_stubbed(:retirement_state_product, forecast: :customer, surplus_retirement_income_cents: 0)
        end

        it { expect(subject.to_i).to eq 1000 }
      end
    end
  end

  context "when PRIVATRENTE_FONDS" do
    before { allow(retirement_product).to receive(:category).and_return :privatrente_fonds }

    it { expect(subject.to_i).to eq 500 }
  end

  context "when RIESTER_FONDS" do
    before { allow(retirement_product).to receive(:category).and_return :riester_fonds }

    it { expect(subject.to_i).to eq 10_000 }

    context "with empty retirement_three_percent_growth_cents" do
      before do
        allow(retirement_product).to receive(:retirement_three_percent_growth_cents).and_return nil
      end

      it { expect(subject.to_i).to eq 2370 }
    end
  end

  context "when BASIS_FONDS" do
    before { allow(retirement_product).to receive(:category).and_return :basis_fonds }

    it { expect(subject.to_i).to eq 10_000 }

    context "with empty retirement_three_percent_growth_cents" do
      before do
        allow(retirement_product).to receive(:retirement_three_percent_growth_cents).and_return nil
      end

      it { expect(subject.to_i).to eq 2370 }
    end
  end

  context "when RIESTER_FONDS_NON_INSURANCE" do
    before { allow(retirement_product).to receive(:category).and_return :riester_fonds_non_insurance }

    it "raises an error" do
      expect { subject.to_i }.to raise_error(NotImplementedError)
    end
  end

  context "when KAPITALLEBENSVERSICHERUNG" do
    before { allow(retirement_product).to receive(:category).and_return :kapitallebensversicherung }

    it "calls spicific formula" do
      expect(subject.to_i).to eq 68
    end
  end

  context "when PENSIONSFONDS" do
    before { allow(retirement_product).to receive(:category).and_return :pensionsfonds }

    it { expect(subject.to_i).to eq 500 }
  end

  context "when DIREKTZUSAGE" do
    before { allow(retirement_product).to receive(:category).and_return :direktzusage }

    it "calls spicific formula" do
      expect(Domain::Retirement::Formulas::Direktzusage).to receive(:surplus)
      subject.to_i
    end
  end
end
