# frozen_string_literal: true

FactoryBot.define do
  factory :appointment do
    starts { 1.day.from_now.advance(minutes: 1) }
    ends { 1.day.from_now.advance(hours: 1, minutes: 1) }
    call_type { ValueTypes::CallTypes::PHONE.name.downcase }
    association :appointable, factory: :opportunity
    association :mandate, factory: :wizard_profiled_mandate

    trait :requested do
      state { "requested" }
    end

    trait :accepted do
      state { "accepted" }
    end
  end
end
