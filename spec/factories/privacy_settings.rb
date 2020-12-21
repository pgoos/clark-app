# frozen_string_literal: true

# == Schema Information
#
# Table name: privacy_settings
#
#  id                   :bigint           not null, primary key
#  mandate_id           :integer          not null
#  third_party_tracking :jsonb
#
FactoryBot.define do
  factory :privacy_setting do
    mandate
    third_party_tracking do
      {
        enabled: true,
        accepted_at: DateTime.now,
        valid_until: DateTime.now + 2.years
      }
    end

    trait :third_party_tracking_disabled do
      third_party_tracking do
        {
          enabled: false,
          accepted_at: DateTime.now,
          valid_until: DateTime.now + 2.years
        }
      end
    end

    trait :third_party_tracking_expired do
      third_party_tracking do
        {
          enabled: true,
          accepted_at: DateTime.now - 2.years,
          valid_until: DateTime.now - 1.day
        }
      end
    end
  end
end
