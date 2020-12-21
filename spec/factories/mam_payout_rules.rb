# frozen_string_literal: true

# == Schema Information
#
# Table name: mam_payout_rules
#
#  id                     :integer          not null, primary key
#  products_count         :integer          not null
#  base                   :integer          not null
#  ftl                    :integer          not null
#  sen                    :integer          not null
#  mam_loyalty_group_id   :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null

FactoryBot.define do
  factory :mam_payout_rule do
    products_count { 1 }
    base { 1000 }
    ftl { 1000 }
    sen { 1000 }
    association :mam_loyalty_group
  end
end
