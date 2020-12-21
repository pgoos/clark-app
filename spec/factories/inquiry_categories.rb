# frozen_string_literal: true
# == Schema Information
#
# Table name: inquiry_categories
#
#  id                           :integer          not null, primary key
#  inquiry_id                   :integer
#  category_id                  :integer
#  product_number               :string
#  created_at                   :datetime
#  updated_at                   :datetime
#  deleted_by_customer          :boolean          default(FALSE), not null
#  customer_documents_dismissed :boolean          default(FALSE)
#  cancellation_cause           :integer          default("no_cancellation_cause")
#  state                        :string           default("in_progress")
#


FactoryBot.define do
  factory :inquiry_category do
    category
    inquiry

    trait :product_number do
      state { "" }
    end

    trait :in_progress do
      state { "in_progress" }
    end

    trait :completed do
      state { "completed" }
    end

    trait :insurer_denied_information_access do
      state { "cancelled" }
      cancellation_cause { :insurer_denied_information_access }
    end

    trait :customer_not_insured_person do
      state { "cancelled" }
      cancellation_cause { :customer_not_insured_person }
    end

    trait :contract_not_found do
      state { "cancelled" }
      cancellation_cause { :contract_not_found }
    end

    trait :cancelled_by_customer do
      state { "cancelled" }
      cancellation_cause { :cancelled_by_customer }
    end

    trait :shallow do
      category { nil }
      inquiry { nil }
    end
  end
end
