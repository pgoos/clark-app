# frozen_string_literal: true

FactoryBot.define do
  factory :retirement_corporate_product, class: "Retirement::CorporateProduct" do
    trait :direktversicherung_classic do
      category { "direktversicherung_classic" }
    end

    trait :direktversicherung_fonds do
      category { "direktversicherung_fonds" }
    end

    trait :pensionskasse do
      category { "pensionskasse" }
    end

    trait :unterstuetzungskasse do
      category { "unterstuetzungskasse" }
    end

    trait :direktzusage do
      category { "direktzusage" }
    end

    trait :pensionsfonds do
      category { "pensionsfonds" }
    end
  end
end
