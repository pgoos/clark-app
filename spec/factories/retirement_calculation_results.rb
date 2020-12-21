# frozen_string_literal: true

FactoryBot.define do
  factory :retirement_calculation_result, class: "Retirement::CalculationResult" do
    state { "new" }
    desired_income { 100_000 }
    recommended_income { 150_000 }
    retirement_gap { 50_000 }
  end
end
