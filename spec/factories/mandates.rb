# frozen_string_literal: true
# == Schema Information
#
# Table name: mandates
#
#  id                         :integer          not null, primary key
#  first_name                 :string
#  last_name                  :string
#  birthdate                  :datetime
#  gender                     :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  info                       :json
#  state                      :string
#  tos_accepted_at            :datetime
#  confirmed_at               :datetime
#  tracking_code              :string
#  newsletter                 :jsonb
#  company_name               :string
#  variety                    :string
#  encrypted_iban             :string
#  encrypted_iban_iv          :string
#  voucher_id                 :integer
#  qualitypool_id             :integer
#  contactable_at             :string
#  preferred_locale           :string
#  satisfaction               :jsonb            not null
#  loyalty                    :jsonb            not null
#  owner_ident                :string           default("clark"), not null
#  accessible_by              :jsonb            not null
#  health_and_care_insurance  :integer          default(0), not null
#  church_membership          :boolean          default(FALSE), not null
#  health_consent_accepted_at :datetime
#

FactoryBot.define do
  factory :mandate do
    sequence(:first_name) { |n| "John#{n}" }
    last_name     { "Roe" }
    birthdate     { 20.years.ago.to_date }
    gender        { :male }
    tracking_code { "abc" }

    # TODO: Move address creation to traits
    with_address

    trait :accepted do
      state { "accepted" }
      tos_accepted_at { Time.zone.now.advance(days: -1) }
    end

    trait :created do
      state { "created" }
    end

    trait :revoked do
      state { "revoked" }
    end

    trait :not_started do
      state { :not_started }
    end

    trait :in_creation do
      state { :in_creation }
    end

    trait :rejected do
      state { :rejected }
    end

    trait :freebie do
      state { :freebie }
    end

    trait :with_phone do
      phone { "+4915112345678" }
    end

    trait :with_address do
      after(:build) do |mandate, e|
        # NOTE: no need to build address if active_address provided in params
        # we can't use check on nil here since active_address is being built
        # automatically if it doesn't exist
        mandate.active_address = build(:address) unless e.instance_variable_get(:@overrides).key?(:active_address)
      end
    end

    trait :wizard_targeted do
      info      { {"wizard_steps" => ["targeting"]} }
      inquiries { build_list :inquiry, 1 }
    end

    trait :wizard_profiled do
      info { {"wizard_steps" => %w[targeting profiling]} }
      user
    end

    trait :wizard_to_be_confirmed do
      inquiries { build_list :inquiry, 1 }
      signature
      confirmed_at    { DateTime.current }
      tos_accepted_at { DateTime.current }
      info { {"wizard_steps" => %w[targeting profiling]} }
      user
    end

    trait :wizard_confirmed do
      inquiries { build_list :inquiry, 1 }
      signature
      confirmed_at    { DateTime.current }
      tos_accepted_at { DateTime.current }
      info { {"wizard_steps" => %w[targeting profiling confirming]} }
      user
    end

    trait :mam do
      loyalty { {mam: {}} }
      association :user, %i[mam_enabled]
    end

    trait :home24 do
      transient do
        order_number { "10123485748" }
        export_state { nil }
      end
      loyalty {
        {
          home24:
            {
              "export_state" => export_state,
              "order_number" => order_number
            }
        }
      }

      association :user, %i[home24]
    end

    trait :mam_with_status do
      transient do
        mmAccountNumber { "992223020632830" }
      end
      loyalty {
        {mam: {"mmAccountNumber"     => mmAccountNumber,
               "customerNumber"      => "236325650",
               "primaryMmCardNumber" => "992003020632836",
               "status"              => "BASE",
               "numberStars"         => "0",
               "lastStarChangeDate"  => ""}}
      }
      association :user, [:mam_enabled]
    end

    trait :with_lead do
      association :lead, factory: %i[lead without_mandate]
    end

    trait :with_user do
      association :user
    end

    # Implemented this trait because of we have a flaky issue,
    # from time to time it creates a mandate WITHOUT user with this expression -
    # association :mandate,
    #          factory: %i[mandate with_user],
    #          strategy: :build

    trait :build_with_user do
      transient do
        password { }
      end

      after(:build) do |mandate, obj|
        build :user, mandate: mandate, password: obj.password
      end
    end

    trait :with_retirement_cockpit do
      association :retirement_cockpit, factory: [:retirement_cockpit]
    end

    trait :owned_by_clark do
      owner_ident { "clark" }
    end

    trait :owned_by_n26 do
      owner_ident { "n26" }
    end

    trait :owned_by_partner do
      owner_ident { "partner" }
    end

    trait :vip do
      variety { :vip }
    end

    trait :critic do
      variety { :critic }
    end

    trait :confirmed do
      confirmed_at { Time.zone.now }
    end

    trait :with_accepted_tos do
      tos_accepted_at { Time.zone.now }
    end

    trait :prospect_customer do
      customer_state { "prospect" }
    end

    trait :self_service_customer do
      customer_state { "self_service" }
    end

    trait :mandate_customer do
      customer_state { "mandate_customer" }
    end

    trait :without_address do
      after(:build) do |mandate|
        mandate.skip_active_address_validation = true
        mandate.active_address = build(:invalid_address)
      end
    end

    factory :wizard_targeted_mandate,    traits: %i[wizard_targeted]
    factory :wizard_profiled_mandate,    traits: %i[wizard_profiled]
    factory :signed_unconfirmed_mandate, traits: %i[wizard_to_be_confirmed]
    factory :accepted_mandate,           traits: %i[accepted wizard_confirmed]
    factory :created_mandate,            traits: %i[created wizard_confirmed]
    factory :revoked_mandate,            traits: %i[revoked wizard_confirmed]
    factory :invalid_mandate,            traits: %i[in_creation without_address]
  end

  factory :empty_mandate, class: "Mandate" do
    first_name { nil }
    last_name  { nil }
    birthdate  { nil }
    phone      { nil }
  end
end
