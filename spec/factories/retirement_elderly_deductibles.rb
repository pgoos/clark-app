# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_elderly_deductibles
#
#  id                                   :integer          not null, primary key
#  year_customer_turns_65               :integer
#  deductible_percentage                :integer
#  deductible_max_amount_cents_cents    :integer          default(0), not null
#  deductible_max_amount_cents_currency :string           default("EUR"), not null
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#


FactoryBot.define do
  factory :retirement_elderly_deductible, class: "Retirement::ElderlyDeductible" do
  end
end
