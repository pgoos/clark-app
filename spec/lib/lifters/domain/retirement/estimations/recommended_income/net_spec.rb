# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Estimations::RecommendedIncome::Net do
  subject(:income) do
    described_class.new(
      yearly_gross_salary: 5_000_000,
      birthdate: birthdate
    )
  end

  before do
    Timecop.freeze(Date.new(2018, 11, 13))
    allow(Domain::Retirement::IncomeTaxPercentage).to \
      receive(:call).and_return(30.83)
  end

  after { Timecop.return }

  context "mandate with birthdate" do
    let(:birthdate) { Date.parse("01.01.1985") }

    it "#call" do
      expect(income.call).to eq 254_969
    end

    it "calls income tax percentage service" do
      expect(Domain::Retirement::IncomeTaxPercentage).to receive(:call).with(6_563_484)
      income.call
    end
  end

  context "mandate without birthdate" do
    let(:birthdate) { nil }

    it "#call" do
      expect(income.call).to eq 0
    end
  end
end
