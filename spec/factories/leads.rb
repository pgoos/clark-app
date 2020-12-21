# == Schema Information
#
# Table name: leads
#
#  id                    :integer          not null, primary key
#  email                 :string
#  subscriber            :boolean          default(TRUE)
#  terms                 :string
#  campaign              :string
#  registered_with_ip    :inet
#  infos                 :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  mandate_id            :integer
#  confirmed_at          :datetime
#  installation_id       :string
#  source_data           :jsonb
#  state                 :string           default("active")
#  inviter_code          :string
#  restore_session_token :string
#

FactoryBot.define do
  factory :lead do
    mandate
    email { Faker::Internet.email(name: mandate&.first_name) }
    terms { "term-document.pdf" }
    campaign { "frankfurt-coffee" }
    registered_with_ip { Faker::Internet.ip_v4_address }
    infos {}

    trait :without_mandate do
      mandate { nil }
    end

    trait :with_mandate do
      association :mandate, factory: :mandate
    end

    trait :mam_enabled do
      source_data { { adjust: {network: "mam"} } }
    end

    trait :payback_enabled do
      source_data { { adjust: { network: "payback" } } }
    end

    trait :home24 do
      source_data { { adjust: { network: "home24" } } }
    end

    factory :device_lead do
      installation_id { Faker::Internet.device_token }
      email { nil }
    end

    trait :anonymous_lead do
      source_data { { anonymous_lead: true } }
    end

    trait :malburg_mandate do
      source_data { { adjust: {network: "Malburg"} } }
    end
  end
end
