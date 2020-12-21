# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_income_taxes
#
#  id                           :integer          not null, primary key
#  income_cents                 :integer          default(0), not null
#  income_currency              :string           default("EUR"), not null
#  income_tax_percentage        :integer
#  income_tax_church_percentage :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#


FactoryBot.define do
  factory :retirement_income_tax, class: "Retirement::IncomeTax" do
  end
end
