# frozen_string_literal: true

require Rails.root.join("app", "composites", "payback", "entities", "customer")

FactoryBot.define do
  factory :payback_customer_entity, class: "Payback::Entities::Customer" do
    initialize_with do
      mandate

      new(
        id: id,
        payback_enabled: payback_enabled,
        payback_data: payback_data,
        mandate_state: mandate_state,
        accepted_at: accepted_at_date
      )
    end

    id { mandate.try(:id) || Faker::Number.number(digits: 2) }
    mandate_state { "created" }
    payback_enabled { true }
    payback_data {}
    accepted_at_date {}

    trait :accepted do
      mandate_state { "accepted" }
      accepted_at_date { Payback::Entities::Customer::REWARDABLE_PERIOD.ago + 1.day }
    end

    trait :with_payback_data do
      transient do
        paybackNumber { Luhn.generate(16, prefix: "308342") }
        rewardedPoints { {"locked" => 0, "unlocked" => 0} }
        paybackAuthenticationFailed { false }
      end

      payback_data do
        {
          "paybackNumber" => paybackNumber,
          "rewardedPoints" => rewardedPoints,
          "authenticationFailed" => paybackAuthenticationFailed
        }
      end
    end

    trait :outside_eligible_period do
      accepted_at_date { Payback::Entities::Customer::REWARDABLE_PERIOD.ago }
    end

    mandate do
      build(
        :mandate,
        state: mandate_state,
        user: build(:user, :payback_enabled),
        loyalty: {payback: payback_data}
      )
    end

    before(:create) do |customer, obj|
      # When using create Strategy that will call save! method in defined object and
      # as this is just a PORO then save! doesn't make sense
      customer.define_singleton_method(:save!) do
        obj.mandate.save!
        @attributes[:id] = obj.mandate.id
      end
    end

    after(:create) do |account|
      account.instance_eval("undef :save!")
    end
  end
end
