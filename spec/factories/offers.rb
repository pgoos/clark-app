# frozen_string_literal: true
# == Schema Information
#
# Table name: offers
#
#  id                          :integer          not null, primary key
#  mandate_id                  :integer
#  state                       :string           default("in_creation")
#  offered_on                  :datetime
#  valid_until                 :datetime
#  note_to_customer            :text
#  created_at                  :datetime
#  updated_at                  :datetime
#  displayed_coverage_features :string           default([]), is an Array
#  active_offer_selected       :boolean          default(FALSE)
#  info                        :jsonb            not null
#

FactoryBot.define do
  factory :offer do
    association :opportunity
    mandate

    displayed_coverage_features { %w[feature-1 feature-2 feature-3] }
    note_to_customer { Faker::Lorem.paragraph }

    trait :shallow do
      opportunity { nil }
      mandate { nil }
    end

    trait :in_creation do
      state { "in_creation" }
    end

    factory :offer_with_opportunity_in_initiation_phase do
      association :opportunity, state: :initiation_phase
    end

    factory :active_offer do
      state { "active" }
      offer_options do
        [
          FactoryBot.build(:offer_option, recommended: true),
          FactoryBot.build(:offer_option),
          FactoryBot.build(:offer_option)
        ]
      end

      documents { [FactoryBot.build(:document, document_type: DocumentType.offer_new)] }
      offered_on { DateTime.current }
      valid_until { 1.year.from_now }

      factory :active_offer_with_old_tarif do
        offer_options do
          [
            FactoryBot.build(:offer_option, recommended: true),
            FactoryBot.build(:old_product_option),
            FactoryBot.build(:offer_option)
          ]
        end
      end
    end

    factory :single_offer_product do
      state { "active" }
      offer_options { [FactoryBot.build(:offer_option, recommended: true)] }
      documents     { [FactoryBot.build(:document, document_type: DocumentType.offer_new)] }
      offered_on    { DateTime.current }
      valid_until   { 1.year.from_now }
    end
  end
end
