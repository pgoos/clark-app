# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Formulas::Vermoegen do
  describe ".guaranteed" do
    let(:current_equity) { 25_000 }
    let(:years_till_retirement) { 34 }

    context "male" do
      let(:gender) { "male" }
      let(:remaining_life_years) { 20.67 }

      it { expect(subject.guaranteed(current_equity, years_till_retirement, gender, remaining_life_years)).to eq 128.4 }
    end

    context "female" do
      let(:gender) { "female" }
      let(:remaining_life_years) { 23.79 }

      it { expect(subject.guaranteed(current_equity, years_till_retirement, gender, remaining_life_years)).to eq 131.5 }
    end
  end
end
