# frozen_string_literal: true

# == Schema Information
#
# Table name: advertiser_channel_mappings
#
#  id            :integer          not null, primary key
#  ad_provider   :string           not null
#  campaign_name :string
#  adgroup_name  :string
#  creative_name :string
#  mkt_channel   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :advertiser_channel_mapping do
    ad_provider { "CuteAds" }
    campaign_name { "Campaign 1" }
    adgroup_name { "Ad Group " }
    creative_name { "CREATIVE NAME" }
    organic

    trait :organic do
      mkt_channel { :organic }
    end

    trait :facebook do
      mkt_channel { :facebook }
    end

    trait :email do
      mkt_channel { :email }
    end
  end
end
