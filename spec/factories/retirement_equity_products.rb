# frozen_string_literal: true

FactoryBot.define do
  factory :retirement_equity_product, class: "Retirement::EquityProduct" do
    product
    state { :created }
    equity_today { 1000 }
  end
end
