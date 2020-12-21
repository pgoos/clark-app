# frozen_string_literal: true

# == Schema Information
#
# Table name: business_events
#
#  id                 :integer          not null, primary key
#  person_id          :integer
#  person_type        :string
#  entity_id          :integer
#  entity_type        :string
#  action             :string
#  created_at         :datetime
#  metadata           :jsonb
#  audited_mandate_id :integer
#

FactoryBot.define do
  factory :business_event do
    person_id { 1 }
    person_type { "User" }
    entity_id { 1 }
    entity_type { "Category" }
    action { "update" }

    factory :complete_opportunity_business_event do
      person_id { entity.admin_id }
      person_type { "Admin" }
      entity_id { entity.id }
      entity_type { "Opportunity" }
      action { "complete" }
    end

    factory :cancel_opportunity_business_event do
      person_id { entity.admin_id }
      person_type { "Admin" }
      entity_id { entity.id }
      entity_type { "Opportunity" }
      action { "cancel" }
    end

    factory :assign_opportunity_business_event do
      person_id { entity.admin_id }
      person_type { "Admin" }
      entity_id { entity.id }
      entity_type { "Opportunity" }
      action { "assign" }
    end

    factory :update_admin_opportunity_business_event do
      person_id { entity.admin_id }
      person_type { "Admin" }
      entity_id { entity.id }
      entity_type { "Opportunity" }
      action { "update" }
      metadata { { admin_id: { new: entity.admin_id, old: nil } } }
    end

    factory :create_opportunity_business_event do
      person_id { entity.admin_id }
      person_type { "Admin" }
      entity_id { entity.id }
      entity_type { "Opportunity" }
      action { "create" }
    end

    trait :with_entity_opportunity do
      association :entity, factory: :opportunity
    end
  end
end
