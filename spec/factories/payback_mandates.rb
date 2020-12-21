# frozen_string_literal: true

FactoryBot.define do
  trait :payback do
    loyalty { {payback: {}} }
    association :lead, :payback_enabled
  end

  trait :payback_with_data do
    transient do
      paybackNumber { "3083426813913804" }
    end
    loyalty {
      {
        payback: {
          "paybackNumber" => paybackNumber,
          "rewardedPoints" => {
            "locked" => 0,
            "unlocked" => 0
          }
        }
      }
    }
    association :user, [:payback_enabled]
  end

  trait(:in_rewardable_payback_period) do
    after(:create) do |mandate|
      acceptance_event = FactoryBot.build(:business_event,
                                          entity_id: mandate.id,
                                          entity_type: "Mandate",
                                          action: "accept",
                                          created_at: Payback::Entities::Customer::REWARDABLE_PERIOD.ago + 1.day)
      mandate.business_events << acceptance_event
      mandate.save
    end
  end

  trait(:outside_rewardable_payback_period) do
    after(:create) do |mandate|
      acceptance_event = FactoryBot.build(:business_event,
                                          entity_id: mandate.id,
                                          entity_type: "Mandate",
                                          action: "accept",
                                          created_at: Payback::Entities::Customer::REWARDABLE_PERIOD.ago)
      mandate.business_events << acceptance_event
      mandate.save
    end
  end
end
