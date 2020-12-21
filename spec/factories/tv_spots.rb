# frozen_string_literal: true
# == Schema Information
#
# Table name: tv_spots
#
#  id                   :integer          not null, primary key
#  tv_channel           :string           not null
#  air_time             :datetime         not null
#  price_cents          :integer          default(0), not null
#  price_currency       :string           default("EUR"), not null
#  vendor_specific_data :jsonb
#  tv_discount_id       :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  spot_id              :string
#  brand                :boolean          not null
#

FactoryBot.define do
  factory :tv_spot do
    tv_channel { "channel" }
    air_time { Time.zone.now }
    price_cents { 2000 }
    price_currency { "EUR" }
    brand { false }
  end
end
