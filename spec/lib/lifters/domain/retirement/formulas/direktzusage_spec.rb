# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Formulas::Direktzusage do
  subject(:calc) { described_class }

  describe ".guaranteed" do
    let(:capital) { 15_300 }
    let(:retirement_year) { 36 }

    context "male" do
      let(:remaining_life_years) { 20.67 }
      let(:gender) { "male" }

      it "calculates guaranteed income using 0.62" do
        expect(described_class.guaranteed(capital, retirement_year, remaining_life_years, gender))
          .to eq 8.848365203851333
      end
    end

    context "female" do
      let(:remaining_life_years) { 23.79 }
      let(:gender) { "female" }

      it "calculates guaranteed income using 0.72" do
        expect(described_class.guaranteed(capital, retirement_year, remaining_life_years, gender))
          .to eq 9.961417900346611
      end
    end
  end

  describe ".surplus" do
    let(:capital_pension) { 10000 }
    let(:retirement_year) { 34 }

    context "male" do
      let(:gender) { "male" }
      let(:remaining_life_years) { 20.67 }

      it "calculates surplus income using 0.62" do
        expect(calc.surplus(capital_pension, retirement_year, remaining_life_years, gender))
          .to eq 51.359302578163486
      end
    end

    context "female" do
      let(:gender) { "female" }
      let(:remaining_life_years) { 23 }

      it "calculates surplus income using 0.72" do
        expect(calc.surplus(capital_pension, retirement_year, remaining_life_years, gender))
          .to eq 54.20318531624498
      end
    end
  end
end
