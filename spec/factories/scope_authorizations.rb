# frozen_string_literal: true

# == Schema Information
#
# Table name: scope_authorizations
#
#  id          :integer          not null, primary key
#  entity      :string
#  subject     :string
#  value       :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :scope_authorization do
    mandates

    trait :mandates do
      entity { "mandates" }
    end

    trait :mandates_owner do
      mandates
      subject { "owner_ident" }
    end

    trait :mandates_variety do
      mandates
      subject { "variety" }
    end
  end
end
