# frozen_string_literal: true

FactoryBot.define do
  factory :admin_performance_classification do
    admin { build(:admin) }
    category { build(:category) }
    level { "not_set" }
  end
end
