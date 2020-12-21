# frozen_string_literal: true

# == Schema Information
#
# Table name: instant_assessments
#
#  ident                :uuid          not null, primary key, default: 'uuid_generate_v4()'
#  category_ident       :string        default(""), not null
#  company_ident        :string        default(""), not null
#  category_description :text          default(""), not null
#  total_evaluation     :jsonb         default({}), not null
#  popularity           :jsonb         default({}), not null
#  customer_review      :jsonb         default({}), not null
#  coverage_degree      :jsonb         default({}), not null
#  price_level          :jsonb         default({}), not null
#  claim_settlement     :jsonb         default({}), not null
#

FactoryBot.define do
  factory :instant_assessment do
    ident { |n| SecureRandom.hex(4) + n.to_s }
    category_ident { |n| SecureRandom.hex(4) + n.to_s }
    company_ident { |n| SecureRandom.hex(4) + n.to_s }
    category_description { Faker::Lorem.paragraph }
    assessment_explanation { Faker::Lorem.paragraph }
    total_evaluation { { value: 71 } }
    popularity { { value: 65, description: Faker::Lorem.paragraph } }
    customer_review { { value: 91, description: Faker::Lorem.paragraph } }
    coverage_degree { { value: 85, description: Faker::Lorem.paragraph } }
    price_level { { value: 60, description: Faker::Lorem.paragraph } }
    claim_settlement { { value: 61, description: Faker::Lorem.paragraph } }

    trait :without_customer_review do
      customer_review { { value: nil, description: Faker::Lorem.paragraph } }
    end
  end
end
