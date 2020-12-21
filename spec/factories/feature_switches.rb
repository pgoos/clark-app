# == Schema Information
#
# Table name: feature_switches
#
#  id         :integer          not null, primary key
#  key        :string
#  active     :boolean
#  limit      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :feature_switch do
    sequence(:key) { |n| 'feature_' + n.to_s }
    active { false }
  end
end
