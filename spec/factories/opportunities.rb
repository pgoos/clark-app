# frozen_string_literal: true
# == Schema Information
#
# Table name: opportunities
#
#  id                 :integer          not null, primary key
#  mandate_id         :integer
#  admin_id           :integer
#  source_id          :integer
#  source_type        :string
#  source_description :string
#  category_id        :integer
#  state              :string
#  old_product_id     :integer
#  sold_product_id    :integer
#  offer_id           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  is_automated       :boolean          default(FALSE)
#  metadata           :jsonb
#  followup_situation :string           default(NULL)
#

FactoryBot.define do
  factory :opportunity do
    association :mandate, factory: :wizard_profiled_mandate
    is_automated { false }
    category { build(:category) }
    source_description { "Customer via Chat" }
    admin

    trait :lost do
      state { "lost" }
    end

    trait :offer_phase do
      state { "offer_phase" }
    end

    trait :created do
      state { "created" }
    end

    trait :initiation_phase do
      state { "initiation_phase" }
    end

    trait :completed do
      state { "completed" }
    end

    trait :shallow do
      mandate { nil }
      category { nil }
      admin { nil }
    end

    trait :with_retirement_category do
      association :category, factory: :category_retirement
    end

    trait :skip_validations do
      to_create { |instance| instance.save(validate: false) }
    end

    factory :shallow_opportunity do
      mandate { nil }
      category { nil }
      admin { nil }

      to_create { |opportunity| opportunity.save(validate: false) }
    end

    trait :unassigned do
      admin { nil }
    end

    factory :opportunity_with_offer do
      state { "offer_phase" }

      after(:create) do |opportunity|
        opportunity.offer = create(
          :active_offer, opportunity: opportunity, mandate: opportunity.mandate
        )
        opportunity.save
      end
    end

    factory :opportunity_with_expired_offer do
      state { "offer_phase" }

      after(:create) do |opportunity|
        opportunity.offer = create(
          :offer, opportunity: opportunity, mandate: opportunity.mandate, state: "expired"
        )
        opportunity.save
      end
    end

    factory :opportunity_with_offer_in_creation do
      state { "initiation_phase" }

      after(:create) do |opportunity|
        opportunity.offer = create(
          :offer, opportunity: opportunity, mandate: opportunity.mandate
        )
        opportunity.save
      end
    end

    factory :opportunity_with_offer_and_old_tarif do
      state { "offer_phase" }

      after(:create) do |opportunity|
        opportunity.offer = create(
          :active_offer_with_old_tarif, opportunity: opportunity, mandate: opportunity.mandate
        )
        opportunity.save
      end
    end

    factory :opportunity_with_single_offer_option do
      state { "offer_phase" }

      after(:create) do |opportunity|
        opportunity.offer = create(
          :single_offer_product, opportunity: opportunity, mandate: opportunity.mandate
        )
        opportunity.save
      end
    end
  end
end
