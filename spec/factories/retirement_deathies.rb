# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_deathies
#
#  id         :integer          not null, primary key
#  birth_year :integer
#  male       :decimal(4, 2)    not null
#  female     :decimal(4, 2)    not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#


FactoryBot.define do
  factory :retirement_deathy, class: "Retirement::Deathy" do
  end
end
