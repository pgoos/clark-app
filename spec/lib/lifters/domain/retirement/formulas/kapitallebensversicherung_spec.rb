# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Formulas::Kapitallebensversicherung do
  subject(:calc) { described_class }

  describe ".guaranteed" do
    let(:guaranteed_capital) { 25_000 }

    context "male" do
      let(:gender) { "male" }
      let(:remaining_life_years) { 20.67 }

      it { expect(calc.surplus(guaranteed_capital, remaining_life_years, gender)).to eq 68.79347953332491 }
    end

    context "female" do
      let(:gender) { "female" }
      let(:remaining_life_years) { 23 }

      it { expect(calc.surplus(guaranteed_capital, remaining_life_years, gender)).to eq 72.60273275750255 }
    end

    context "when product retirement year is less than mandate retirement year" do
      let(:gender) { "male" }
      let(:remaining_life_years) { 20.67 }

      it do
        expect(
          calc.surplus(
            guaranteed_capital,
            remaining_life_years,
            gender,
            Date.new(2047, 1, 1),
            Date.new(2047, 2, 1)
          )
        ).to eq 68.85164124116878
      end
    end
  end

  describe ".surplus" do
    let(:possible_capital) { 25_000 }

    context "male" do
      let(:gender) { "male" }
      let(:remaining_life_years) { 20.67 }

      it { expect(calc.surplus(possible_capital, remaining_life_years, gender)).to eq 68.79347953332491 }
    end

    context "female" do
      let(:gender) { "female" }
      let(:remaining_life_years) { 23 }

      it { expect(calc.surplus(possible_capital, remaining_life_years, gender)).to eq 72.60273275750255 }
    end

    context "when product retirement year is less than mandate retirement year" do
      let(:gender) { "male" }
      let(:remaining_life_years) { 20.67 }

      it do
        expect(
          calc.surplus(
            possible_capital,
            remaining_life_years,
            gender,
            Date.new(2047, 1, 1),
            Date.new(2047, 2, 1)
          )
        ).to eq 68.85164124116878
      end
    end
  end
end
