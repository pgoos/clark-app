# frozen_string_literal: true

# == Schema Information
#
# Table name: tracking_adjust_events
#
#  id              :integer          not null, primary key
#  activity_kind   :string           not null
#  event_time      :datetime         not null
#  event_name      :string
#  params          :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  device_id       :integer
#  mandate_id      :integer
#  installation_id :string
#

FactoryBot.define do
  factory :tracking_adjust_event, class: "Tracking::AdjustEvent" do
    activity_kind { "MyString" }
    event_name { "MyString" }
    params { { "some_key": "some_value" } }
    sequence(:event_time) { |n| (Time.zone.now + n).strftime("%Y-%m-%d %H:%M:%S") }

    transient do
      adid { nil }
    end

    after :build do |record, evaluator|
      if evaluator.adid
        record.params ||= {}
        record.params["adid"] = evaluator.adid
      end
    end

    trait :install do
      activity_kind { "install" }
    end

    trait :session do
      activity_kind { "session" }
    end
  end
end
