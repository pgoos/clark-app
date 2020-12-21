# frozen_string_literal: true

# == Schema Information
#
# Table name: admins
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
#  created_at             :datetime
#  updated_at             :datetime
#  role_id                :integer
#  state                  :string
#  first_name             :string
#  last_name              :string
#  profile_picture        :string
#  email_footer_image     :string
#  work_items             :string           default([]), is an Array
#  access_flags           :string           default([]), is an Array
#  sip_uid                :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#

FactoryBot.define do
  factory :admin do
    email { Faker::Internet.email }
    password { Settings.seeds.default_password }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { ClarkFaker::PhoneNumber.phone_number }
    role factory: :role

    factory :super_admin do
      role { nil }

      after(:build) do |admin|
        admin.role = Role.find_by(identifier: "super_admin")
      end
    end

    factory :advice_admin do
      email { RoboAdvisor::ADVICE_ADMIN_EMAILS.sample }
    end
    factory :gkv_consultants_admin do
      id { Sales::GkvOfferService::GKV_CONSULTANTS.sample }
    end
    factory :low_margin_admin do
      email { RoboAdvisor::ADVICE_ADMIN_EMAILS.sample }
    end

    trait :inactive do
      state { "inactive" }
    end

    trait :sales_consultant do
      access_flags { ["sales_consultation"] }
    end
  end
end
