# == Schema Information
#
# Table name: advertisement_performance_logs
#
#  id                    :integer          not null, primary key
#  start_report_interval :datetime         not null
#  end_report_interval   :datetime         not null
#  ad_provider           :string           not null
#  campaign_name         :string           not null
#  adgroup_name          :string           not null
#  creative_name         :string
#  cost_cents            :integer          default(0), not null
#  cost_currency         :string           default("EUR"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  historical_values     :jsonb
#  provider_data         :jsonb
#  brand                 :boolean          not null
#

FactoryBot.define do
  factory :advertisement_performance_log do
    ad_provider { 'CuteAds' }
    campaign_name { 'Campaign 1' }
    adgroup_name { 'Ad Group 1' }
    start_report_interval { Date.new(2016,1,15).advance(days: -1).to_datetime.utc }
    end_report_interval { Date.new(2016,1,15).advance(days: -1).to_datetime.utc }
    cost_cents { 110 }
    cost_currency { 'EUR' }
    brand { false }
  end
end
