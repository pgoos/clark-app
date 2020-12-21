# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Comparison::Gkv::Calculations::EmployerCalculation do
  let(:premium_percentage) { 1.10 }
  let(:salary) { Money.new("40000", "EUR") }

  it "returns nil if salary is not present" do
    calculation = described_class.new(nil)
    expect(calculation.calculate(premium_percentage)).to be_nil
  end

  it "return nil when it has no premium" do
    calculation = described_class.new(salary)
    expect(calculation.calculate(nil)).to be_nil
  end

  it "gives the right sum based on salary and zuzatsbeitrag" do
    calculation = described_class.new(salary)
    expect(calculation.calculate(premium_percentage)).to eq(Money.new("280", "EUR"))
  end
end
