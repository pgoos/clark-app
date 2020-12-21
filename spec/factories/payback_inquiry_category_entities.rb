# frozen_string_literal: true

require Rails.root.join("app", "composites", "payback", "entities", "inquiry_category")

FactoryBot.define do
  factory :payback_inquiry_category_entity, class: "Payback::Entities::InquiryCategory" do
    initialize_with do
      inquiry_category

      new(
        id: id,
        mandate_id: mandate_id,
        state: state,
        category_ident: category_ident,
        created_at: created_at,
        category_id: category_id,
        category_name: category_name,
        company_name: company_name,
        inquiry_state: inquiry_state
      )
    end

    id { inquiry_category.try(:id) || Faker::Number.number(digits: 2) }
    mandate_id { inquiry_category.inquiry.mandate.try(:id) || Faker::Number.number(digits: 2) }
    state { "in_progress" }
    inquiry_state { "in_creation" }
    category_ident { inquiry_category.category.try(:ident) || "test_category" }
    created_at {
      inquiry_category.try(:created_at) || Faker::Time.between(from: DateTime.now - 15.days, to: DateTime.now)
    }
    category_id { inquiry_category.category_id || Faker::Number.number(digits: 2) }
    category_name { inquiry_category.category&.name || Faker::Lorem.characters(10) }
    company_name { inquiry_category.company_name || Faker::Lorem.characters(10) }

    inquiry_category do
      build(
        :inquiry_category,
        state: state
      )
    end

    trait :cancelled do
      state { "cancelled" }
    end

    before(:create) do |payback_inquiry_category, obj|
      # When using create Strategy that will call save! method in defined object and
      # as this is just a PORO then save! doesn't make sense
      payback_inquiry_category.define_singleton_method(:save!) do
        obj.inquiry_category.save!
      end
    end

    after(:create) do |account|
      account.instance_eval("undef :save!")
    end
  end
end
