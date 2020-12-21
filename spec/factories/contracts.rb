# frozen_string_literal: true

require Rails.root.join("app", "composites", "contracts", "entities", "contract")

FactoryBot.define do
  factory :contract, class: "Contracts::Entities::Contract" do
    sequence(:id) { |n| n }
    state { "details_available" }
    category_ident { Faker::Number.number(digits: 10).to_s }
    category_name { Faker::Commerce.department }
    plan_name { Faker::Commerce.product_name }
    plan_ident { Faker::Number.number(digits: 10).to_s }
    customer_id { 1 }
    analysis_state { "details_missing" }

    association :product,
                :sold_by_us,
                factory: :product,
                strategy: :build,
                mandate: nil,
                company: nil,
                plan: nil,
                premium_price_cents: 5000,
                premium_price_currency: "EUR",
                renewal_period: 12

    initialize_with do
      category = Category.find_by_ident(category_ident)
      category ||= build(:category,
                         name: category_name,
                         ident: category_ident,
                         questionnaire: (self.respond_to?(:questionnaire) ? self.questionnaire : nil),
                         coverage_features: (0..2).to_a.map do |i|
                           build(:coverage_feature, identifier: "identifier_#{i}", value_type: "Text")
                         end)

      product.plan = Plan.find_by_ident(plan_ident)
      product.plan ||= build(:plan,
                             category: category,
                             subcompany: build(:subcompany),
                             vertical: build(:vertical),
                             name: plan_name,
                             coverages: (0..2).to_a.each_with_object({}) do |i, result|
                               result["identifier_#{i}"] = ValueTypes::Text.new("Text #{i}")
                             end)

      product.category = category
      product.mandate = Mandate.find_by(id: customer_id) || build(:mandate)
      product.coverages = product.plan.coverages

      new(
        id: id,
        state: state,
        category_ident: category_ident,
        category_name: category_name,
        plan_name: plan_name,
        plan_ident: plan_ident,
        customer_id: customer_id,
        customer_name: product.mandate.name,
        analysis_state: analysis_state,
        coverage_features: product.category.parsed_coverage_features,
        created_at: Time.zone.now,
        category_tips: [],
        company_name: "Allianz",
        company_ident: SecureRandom.base58(16),
        company_logo: "allianz.de/logo.png",
        rating_score: "4",
        rating_text: "Random text",
        insurance_holder: product.insurance_holder,
        renewal_period: product.renewal_period,
        premium_price: {
          "currency" => Currency::EURO,
          "value" => product.premium_price_cents,
          "unit" => "Money"
        },
        documents: [],
        coverages: product.coverages
      )
    end

    before(:create) do |contract, obj|
      contract.define_singleton_method(:save!) {
        obj.product.plan.category.save!
        obj.product.plan.subcompany.save!
        obj.product.plan.save!
        obj.product.category.save!
        obj.product.mandate.save!
        obj.product.save!
        @attributes[:id] = obj.product.id
        @attributes[:customer_id] = obj.product.mandate_id
      }
    end

    after(:create) do |contract|
      contract.instance_eval("undef :save!")
    end

    trait :with_mandate_id do
      transient do
        mandate_id { nil }
      end

      after(:build) do |_contract, obj|
        obj.product.mandate_id = obj.mandate_id
      end
    end

    trait :with_customer_uploaded_document do
      after(:create) do |contract|
        create(
          :document,
          :with_customer_upload,
          documentable_id: contract.id,
          documentable_type: ::Product.name
        )
      end
    end

    trait :details_missing do
      after(:build) do |_contract, obj|
        obj.product.analysis_state = "details_missing"
      end
    end

    trait :under_analysis do
      analysis_state { "under_analysis" }
      after(:build) do |_contract, obj|
        obj.product.analysis_state = "under_analysis"
      end
    end

    trait :analysis_failed do
      after(:build) do |_contract, obj|
        obj.product.analysis_state = "analysis_failed"
      end
    end

    trait :details_complete do
      after(:build) do |_contract, obj|
        obj.product.analysis_state = "details_complete"
      end
    end

    trait :with_valid_products_advice do
      after(:create) do |_contract, obj|
        create(
          :interaction_advice,
          topic: obj.product,
          helpful: true,
          cta_link: "/de/app/questionnaire/T6wNHI"
        )
      end
    end
  end
end
