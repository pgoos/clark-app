# frozen_string_literal: true

require Rails.root.join("app", "composites", "payback", "entities", "payback_transaction")

FactoryBot.define do
  factory :payback_transaction_entity, class: "Payback::Entities::PaybackTransaction" do
    initialize_with do
      payback_transaction_model

      new(
        id: id,
        mandate_id: mandate_id,
        subject_id: subject.id,
        subject_type: subject.class.name,
        transaction_type: transaction_type,
        receipt_no: receipt_no,
        state: state,
        points_amount: points_amount,
        response_code: response_code,
        info: info,
        created_at: created_at,
        updated_at: updated_at,
        retry_order_count: retry_order_count,
        locked_until: locked_until,
        category_id: subject.category.id,
        category_name: subject.category.name,
        company_name: subject.company_name
      )
    end

    id { payback_transaction_model.try(:id) || Faker::Number.number(digits: 2) }
    mandate_id { payback_transaction_model.try(:mandate_id) || Faker::Number.number(digits: 3) }
    state { "created" }
    points_amount { 20 }
    sequence :receipt_no do |n|
      "#{n}-RECEIPT-NO"
    end
    info { {} }
    created_at { Time.now }
    updated_at { created_at }
    retry_order_count { 0 }
    response_code { "" }
    locked_until { Time.now + 6.weeks }

    payback_transaction_model do
      build(
        :payback_transaction,
        points_amount: points_amount,
        subject_id: subject.id,
        subject_type: subject.class.name,
        state: state,
        info: info,
        receipt_no: receipt_no,
        transaction_type: transaction_type,
        locked_until: locked_until,
        response_code: response_code
      )
    end

    trait :with_inquiry_category do
      association :subject, factory: [:inquiry_category]
    end

    trait :book do
      transaction_type { "book" }
    end

    trait :refund do
      transaction_type { "refund" }
    end

    before(:create) do |payback_transaction_repo, obj|
      # When using create Strategy that will call save! method in defined object and
      # as this is just a PORO then save! doesn't make sense
      payback_transaction_repo.define_singleton_method(:save!) do
        obj.payback_transaction_model.save!
        @attributes[:id] = obj.payback_transaction_model.id
        @attributes[:mandate_id] = obj.payback_transaction_model.mandate_id
      end
    end

    after(:create) do |account|
      account.instance_eval("undef :save!")
    end
  end
end
