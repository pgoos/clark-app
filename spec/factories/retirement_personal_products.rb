# frozen_string_literal: true

FactoryBot.define do
  factory :retirement_personal_product, class: "Retirement::PersonalProduct" do
    product

    trait :private_rentenversicherung do
      category { "private_rentenversicherung" }
    end

    trait :basis_classic do
      category { "basis_classic" }
    end

    trait :riester_classic do
      category { "riester_classic" }
    end

    trait :basis_fonds do
      category { "basis_fonds" }
    end

    trait :riester_fonds do
      category { "riester_fonds" }
    end

    trait :kapitallebensversicherung do
      category { "kapitallebensversicherung" }
    end

    trait :riester_fonds_non_insurance do
      category { "riester_fonds_non_insurance" }
    end

    trait :privatrente_fonds do
      category { "privatrente_fonds" }
    end
  end
end
