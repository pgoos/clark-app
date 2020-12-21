# frozen_string_literal: true

# == Schema Information
#
# Table name: partners
#
#  id             :bigint(8)        not null, primary key
#  name           :string
#  ident          :string           not null
#  active         :boolean          default(TRUE)
#  owned_by_clark :boolean          default(FALSE)
#  metadata       :jsonb
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_partners_on_ident  (ident) UNIQUE
#

FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Partner#{n}" }
    sequence(:ident) { |n| SecureRandom.hex(4) + n.to_s }
    active { false }
    owned_by_clark { false }

    trait :active do
      active { true }
    end

    trait :inactive do
      active { false }
    end
  end
end
