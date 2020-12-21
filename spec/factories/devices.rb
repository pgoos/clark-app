# frozen_string_literal: true

# == Schema Information
#
# Table name: devices
#
#  id                 :integer          not null, primary key
#  token              :string
#  os                 :string
#  os_version         :string
#  manufacturer       :string
#  model              :string
#  user_id            :integer
#  permissions        :json
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  arn                :string
#  installation_id    :string
#  advertiser_id      :string
#  advertiser_id_type :string
#

FactoryBot.define do
  factory :device do
    sequence(:installation_id) { |n| "7eb7cfedef752d762a8280a66572b451006a2b6edf4096bef158415fda73e40#{n}" }
    os           { "ios" }
    os_version   { "9.2.0" }
    manufacturer { "Apple" }
    model        { "iPhone7,1" }
    token        { SecureRandom.hex(32) }
    arn          { "#{Settings.sns.platform_arns.ios}/#{SecureRandom.uuid}" }
    permissions  { {tracking: true, push_enabled: true} }
  end
end
