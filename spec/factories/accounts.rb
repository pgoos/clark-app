# frozen_string_literal: true

require Rails.root.join("app", "composites", "customer", "constituents", "account", "entities", "account")

FactoryBot.define do
  factory :account, class: "Customer::Constituents::Account::Entities::Account" do
    initialize_with do
      user

      new(
        id: id,
        customer_id: customer_id,
        state: state,
        email: email,
        confirmed_at: confirmed_at
      )
    end

    id { user.id || Faker::Number.number(digits: 2) }
    email { Faker::Internet.email }
    confirmed_at { 1.day.ago }
    customer_id { Faker::Number.number(digits: 2) }
    state { "active" }

    user do
      build(
        :user,
        email: email,
        mandate_id: customer_id,
        state: state,
        confirmed_at: confirmed_at
      )
    end

    trait :active do
      state { "active" }
    end

    trait :inactive do
      state { "inactive" }
    end

    before(:create) do |account, obj|
      # When using create Strategy that will call save! method in defined object and
      # as this is just a PORO then save! doesn't make sense
      account.define_singleton_method(:save!) do
        obj.user.save!
        @attributes[:id] = obj.user.id
      end
    end

    after(:create) do |account|
      account.instance_eval("undef :save!")
    end
  end
end
