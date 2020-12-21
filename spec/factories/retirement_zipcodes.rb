# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_zipcodes
#
#  id         :integer          not null, primary key
#  plz        :integer
#  east       :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#


FactoryBot.define do
  factory :retirement_zipcode, class: "Retirement::Zipcode" do
  end
end
