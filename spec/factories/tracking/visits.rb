# frozen_string_literal: true

# == Schema Information
#
# Table name: tracking_visits
#
#  id               :uuid             not null, primary key
#  visitor_id       :uuid
#  ip               :string
#  user_agent       :text
#  referrer         :text
#  landing_page     :text
#  user_id          :integer
#  referring_domain :string
#  search_keyword   :string
#  browser          :string
#  os               :string
#  device_type      :string
#  screen_height    :integer
#  screen_width     :integer
#  country          :string
#  region           :string
#  city             :string
#  postal_code      :string
#  latitude         :decimal(, )
#  longitude        :decimal(, )
#  utm_source       :string
#  utm_medium       :string
#  utm_term         :string
#  utm_content      :string
#  utm_campaign     :string
#  started_at       :datetime
#  mandate_id       :integer
#

FactoryBot.define do
  factory :tracking_visit, class: 'Tracking::Visit' do
    sequence(:id) { |n| "abc123a1-1abc-123a-a0ab-12345a1#{ n.to_s.rjust(5, '0') }" }
    visitor_id { "ab123456-1abc-123a-ab12-ab0ab01a1a12" }
    ip { "127.0.0.1" }
    user_agent { "Mozilla/5.0 (iPhone; CPU iPhone OS 9_0_2 like Mac ..." }
    referrer { "https://www.google.de" }
    landing_page { "https://www.clark.de/de" }
    referring_domain { "https://www.google.de" }
    browser { "Mobile Safari" }
    os { "iOS" }
    device_type { "Mobile" }
    screen_height { 736 }
    screen_width { 414 }
    utm_source { 'CoolAds' }
    utm_medium { "medium" }
    utm_term { "term" }
    utm_content { "content" }
    utm_campaign { "campaign" }
    sequence(:started_at) { |n| "2016-01-02 03:04:#{ n < 10 ? '0' + n.to_s : n.to_s}" }
  end
end
