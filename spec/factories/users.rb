# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  created_at             :datetime
#  updated_at             :datetime
#  state                  :string
#  info                   :hstore
#  referral_code          :string
#  inviter_id             :integer
#  inviter_code           :string
#  subscriber             :boolean          default(TRUE)
#  mandate_id             :integer
#  source_data            :jsonb
#  paid_inviter_at        :datetime
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { Settings.seeds.default_password }
    subscriber { true }
    confirmed_at { 1.day.ago }

    trait :with_mandate do
      association :mandate, factory: :mandate
    end

    trait :mam_enabled do
      source_data { {adjust: {network: "mam"}} }
    end

    trait :payback_enabled do
      source_data { {adjust: {network: "payback"}} }
    end

    trait :home24 do
      source_data { { adjust: { network: "home24" } } }
    end

    trait :primoco_enabled do
      source_data { {adjust: {network: "primoco"}} }
    end

    trait :direkt_1822 do
      source_data { {adjust: {network: "1822direkt"}} }
    end

    factory :device_user do
      installation_id { Faker::Internet.device_token }
    end

    trait :with_installation_id do
      source_data { { installation_id: Faker::Internet.device_token } }
    end
  end
end
