# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Formulas::Fonds do
  subject(:calc) { described_class }

  describe ".guaranteed" do
    let(:guaranteed_pension) { 20_000 }
    let(:guaranteed_capital) { 4_800_000 }
    let(:monthly_factor) { 3416 }

    it { expect(calc.guaranteed(guaranteed_pension, guaranteed_capital, monthly_factor)).to eq 20_000 }

    context "when monthly percent growth is zero" do
      it { expect(calc.guaranteed(0, guaranteed_capital, monthly_factor)).to eq 16_396.8 }
    end

    context "when monthly percent growth is zero" do
      it { expect(calc.guaranteed(nil, guaranteed_capital, monthly_factor)).to eq 16_396.8 }
    end

    context "when product retirement year is less than mandate retirement year" do
      it do
        expect(
          calc.guaranteed(
            nil,
            guaranteed_capital,
            monthly_factor,
            Date.new(2047, 1, 1),
            Date.new(2047, 2, 1)
          ).to_i
        ).to eq 16410
      end
    end
  end

  describe ".surplus" do
    let(:retirement_growth) { 43_112 }
    let(:fund_capital) { 6_693_800 }
    let(:monthly_factor) { 3416 }

    it { expect(calc.surplus(retirement_growth, fund_capital, monthly_factor)).to eq 43_112 }

    context "when retirement growth is zero" do
      it { expect(calc.surplus(0, fund_capital, monthly_factor)).to eq 22_866.020800000002 }
    end

    context "when retirement growth is nil" do
      it { expect(calc.surplus(nil, fund_capital, monthly_factor)).to eq 22_866.020800000002 }
    end
  end
end
