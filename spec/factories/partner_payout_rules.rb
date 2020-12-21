# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_payout_rules
#
#  id             :bigint(8)        not null, primary key
#  mandate_created_from           :date     not null
#  mandate_created_to             :date     not null
#  products_count                 :integer
#  payout_amount                  :integer  not null
#  partner_id                     :integer  not null
#
# Indexes
#
#  partner_payout_unique  (mandate_created_from, mandate_created_to, partner_id) UNIQUE
#

FactoryBot.define do
  factory :partner_payout_rule do
    mandate_created_from { Date.new(2018, 1) }
    mandate_created_to { Date.new(2018, 3) }
    payout_amount { 50 }
    association :partner
  end
end
