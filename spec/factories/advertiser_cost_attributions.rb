# frozen_string_literal: true
# == Schema Information
#
# Table name: advertiser_cost_attributions
#
#  id                    :integer          not null, primary key
#  start_report_interval :datetime
#  end_report_interval   :datetime
#  ad_provider           :string           not null
#  campaign_name         :string
#  adgroup_name          :string
#  creative_name         :string
#  cost_calculation_type :string           not null
#  customer_platform     :string
#  cost_cents            :integer          not null
#  cost_currency         :string           default("EUR")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  brand                 :boolean          not null
#

FactoryBot.define do
  factory :advertiser_cost_attribution do
    ad_provider { "AD_PROVIDER" }
    cost_cents { 100 }
    campaign_name { "CAMPAIGN NAME" }
    adgroup_name { "ADGROUP NAME" }
    creative_name { "CREATIVE NAME" }
    brand { false }

    start_report_interval { 1.day.ago }
    sequence(:end_report_interval) { |n| (Time.zone.now + n.days).to_s }
    comission

    trait :comission do
      cost_calculation_type { :comission }
    end

    trait :fixed do
      cost_calculation_type { :fixed }
    end

    trait :cpi do
      cost_calculation_type { :cpi }
    end
  end
end
