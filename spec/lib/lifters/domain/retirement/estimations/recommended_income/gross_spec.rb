# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Estimations::RecommendedIncome::Gross do
  subject(:income) { described_class.new birthdate, 5_000_000 }

  before { Timecop.freeze(Date.new(2018, 11, 13)) }

  after { Timecop.return }

  context "mandate with birthdate" do
    let(:birthdate) { Date.parse("01.01.1985") }

    it "#call" do
      expect(income.call).to eq 437_566
    end
  end

  context "mandate without birthdate" do
    let(:birthdate) { nil }

    it "#call" do
      expect(income.call).to eq 0
    end
  end
end
