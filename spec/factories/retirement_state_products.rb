# frozen_string_literal: true

FactoryBot.define do
  factory :retirement_state_product, class: "Retirement::StateProduct" do
    product
    forecast { :initial }
  end
end
