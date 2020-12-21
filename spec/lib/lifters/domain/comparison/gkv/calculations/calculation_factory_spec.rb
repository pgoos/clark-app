# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Comparison::Gkv::Calculations::CalculationFactory do
  let(:salary) { "40000" }
  let(:arbeitnehmer_type) { "Arbeitnehmer" }
  let(:auszubildenger_type) { "Auszubildender" }
  let(:self_employed_type) { "Selbstständiger" }
  let(:class_type) { Domain::Comparison::Gkv::Calculations::EmployerCalculation }
  let(:student_type) { Domain::Comparison::Gkv::Calculations::StudentCalculation }

  it "throws an error for unknown type" do
    expect {
      described_class.build("bananas")
    }.to raise_error(ArgumentError)
  end

  it "bulds calculation with proper class" do
    employer_calculation = described_class.build(arbeitnehmer_type, salary)

    expect(employer_calculation).to be_a(class_type)
  end

  it "bulds calculation with salary" do
    employer_calculation = described_class.build(arbeitnehmer_type, salary)

    expect(employer_calculation.salary).to eq(Money.new(salary.to_i * 100, "EUR"))
  end

  it "buils student calculations without salary" do
    employer_calculation = described_class.build("Studentenbeitrag")
    expect(employer_calculation).to be_a(student_type)
  end

  context "Salary is capped at the maximum value for these types" do
    large_sum = (Domain::Comparison::Gkv::Calculations::CalculationFactory::MAX_SALARY + 100000)

    it "is Arbeitnehmer" do
      employer_calculation = described_class.build(arbeitnehmer_type, Domain::Comparison::Gkv::Calculations::CalculationFactory::MAX_SALARY)
      employer_calculation_2 = described_class.build(arbeitnehmer_type, large_sum)
      expect(employer_calculation.salary).to eq(employer_calculation_2.salary)
    end

    it "is Auszubildenger" do
      auszubildenger_calculation = described_class.build(auszubildenger_type, Domain::Comparison::Gkv::Calculations::CalculationFactory::MAX_SALARY)
      auszubildenger_calculation_2 = described_class.build(auszubildenger_type, large_sum)
      expect(auszubildenger_calculation.salary).to eq(auszubildenger_calculation_2.salary)
    end

    it "is Selfemployed" do
      self_employed_calculation = described_class.build(self_employed_type, Domain::Comparison::Gkv::Calculations::CalculationFactory::MAX_SALARY)
      self_employed_calculation_2 = described_class.build(self_employed_type, large_sum)
      expect(self_employed_calculation.salary).to eq(self_employed_calculation_2.salary)
    end
  end
end
