# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_pensions
#
#  id                    :integer          not null, primary key
#  retirement_date_start :date             not null
#  retirement_date_end   :date
#  pension_value_east    :decimal(5, 2)    not null
#  pension_value_west    :decimal(5, 2)    not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#


FactoryBot.define do
  factory :retirement_pension, class: "Retirement::Pension" do
  end
end
