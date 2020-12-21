# frozen_string_literal: true
# == Schema Information
#
# Table name: plan_filters
#
#  id          :integer          not null, primary key
#  category_id :integer
#  key         :string
#  values      :text             is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :plan_filter do
    key { "nTrfWrkID" }
    values { [3310] }
    association :category
  end
end
