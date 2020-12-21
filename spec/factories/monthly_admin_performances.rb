# frozen_string_literal: true

FactoryBot.define do
  factory :monthly_admin_performance do
    performance_level { {} }
    revenue { Faker::Number.between.floor(3) }
    sequence(:calculation_date) { |n| DateTime.now.beginning_of_month + n.days }
    open_opportunities { 10 }
    open_opportunities_category_counts { { Indent1: 10 } }
    algo_version { "default_version" }
    performance_matrix do
      conversion_rate = Faker::Number.between(from: 0.1, to: 0.9)
      [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140].each_with_object({}) do |row_bucket, result|
        result[row_bucket] = {}
        [3000, 9000, 17_000, 23_000, 27_000, 33_000, 47_000, 53_000, 70_000].each do |col_bucket|
          result[row_bucket][col_bucket] = conversion_rate
        end
      end
    end
  end
end
