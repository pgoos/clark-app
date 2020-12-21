# frozen_string_literal: true

# == Schema Information
#
# Table name: mam_loyalty_group
#
#  id                     :integer          not null, primary key
#  name                   :string
#  valid_from             :date
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  campaign_ident         :string
#  base_loyalty_group_id  :integer
#  default_fallback       :boolean
#

FactoryBot.define do
  factory :mam_loyalty_group do
    valid_from { 1.month.ago.to_date }
    sequence(:campaign_ident) { |n| "campaign#{n}" }
  end
end
