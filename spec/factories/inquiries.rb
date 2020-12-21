# frozen_string_literal: true

# == Schema Information
#
# Table name: inquiries
#
#  id            :integer          not null, primary key
#  state         :string
#  created_at    :datetime
#  updated_at    :datetime
#  mandate_id    :integer
#  company_id    :integer
#  remind_at     :date
#  contacted_at  :datetime
#  subcompany_id :integer
#  gevo          :integer          default(0), not null
#

FactoryBot.define do
  factory :inquiry do
    company { build(:company) }
    mandate

    trait :accepted do
      state { "pending" }
    end

    trait :completed do
      state { "completed" }
    end

    trait :contacted do
      state { "contacted" }
    end

    trait :cancelled do
      state { "canceled" }
    end

    trait :pending do
      state { "pending" }
    end

    trait :in_creation do
      state { "in_creation" }
    end

    trait :shallow do
      company { nil }
      mandate { nil }
    end

    factory :accepted_inquiry, traits: [:accepted]
  end
end
