# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_retirement_age_birth_years
#
#  id         :integer          not null, primary key
#  year       :integer          not null
#  age        :decimal(10, 8)   not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#


FactoryBot.define do
  factory :retirement_retirement_age_birth_year, class: "Retirement::RetirementAgeBirthYear" do
  end
end
