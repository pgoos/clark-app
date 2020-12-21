# frozen_string_literal: true

# == Schema Information
#
# Table name: scope_role_authorizations
#
#  id                     :integer          not null, primary key
#  scope_authorization_id :integer
#  role_id                :integer
#

FactoryBot.define do
  factory :scope_role_authorization do
    trait :with_scope_authorization do
      scope_authorization
    end

    trait :with_role do
      role
    end
  end
end
