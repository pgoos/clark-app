# frozen_string_literal: true

FactoryBot.define do
  factory :sales_campaign do
    name { "Adsense HM Campaign" }
    description { "Adsensese campaign created for HM Customers in 2021" }
    active { true }
  end
end
