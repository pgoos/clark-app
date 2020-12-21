# frozen_string_literal: true

FactoryBot.define do
  factory :advertisement_performance_log_entry, class: "Domain::Cost::AdvertisementPerformanceLog::Importer::Entry" do
    initialize_with do
      new(
        id: id,
        ad_provider: ad_provider,
        brand: brand,
        campaign_name: campaign_name,
        cost_cents: cost_cents,
        adgroup_name: adgroup_name,
        creative_name: creative_name,
        day: day
      )
    end

    id { Faker::Number.number(digits: 2) }
    ad_provider { Faker::Lorem.words(number: 2).join(" ") }
    brand { Faker::Boolean.boolean }
    campaign_name { Faker::Lorem.words(number: 2).join(" ") }
    cost_cents { Faker::Number.number(digits: 4) }
    adgroup_name { "-" }
    creative_name { "-" }
    day { Faker::Date.between(from: 1.year.ago, to: Date.today).strftime("%d.%m.%Y") }
  end
end
