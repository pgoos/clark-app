# frozen_string_literal: true

# == Schema Information
#
# Table name: cost_centers
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :cost_center, class: "Accounting::CostCenter" do
    sequence(:name) { |n| "Test cost center #{n}" }
  end
end
