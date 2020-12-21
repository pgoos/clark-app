# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Comparison::Gkv::Calculations::StudentCalculation do
  let(:premium_percentage) { 1.10 }
  let(:salary) { Money.new("40000", "EUR") }

  it "return nil when it has no premium" do
    calculation = described_class.new
    expect(calculation.calculate(nil)).to be_nil
  end

  it "gives the right sum based on salary and zuzatsbeitrag" do
    calculation = described_class.new
    expect(calculation.calculate(premium_percentage)).to eq(Money.new("7347","EUR"))
  end
end
