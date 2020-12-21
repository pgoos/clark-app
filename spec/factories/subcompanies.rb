# frozen_string_literal: true
# == Schema Information
#
# Table name: subcompanies
#
#  id                 :integer          not null, primary key
#  company_id         :integer
#  ff_ident           :string
#  bafin_id           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  name               :string
#  pools              :string           default([]), is an Array
#  info               :hstore
#  softfair_ids       :integer          default([]), is an Array
#  uci                :string
#  principal          :boolean
#  qualitypool_ident  :string
#  ident              :string
#  metadata           :jsonb
#  revenue_generating :boolean          default(FALSE)
#

FactoryBot.define do
  factory :subcompany do
    verticals { [build(:vertical)] }
    association :company, strategy: :build
    name { Faker::Company.name }
    ff_ident { "ff#{SecureRandom.hex(2)}" }
    bafin_id { rand(1_000..9_999) }
    street { "Subcompany Street" }
    house_number { "345" }
    zipcode { "54321" }
    city { "Subcompany Town" }
    country_code { "DE" }

    info {
      {
        info_email: Faker::Internet.email(name: name.parameterize),
        mandates_email: Faker::Internet.email(name: name.parameterize)
      }
    }

    metadata {
      {
        rating: {
          text: {
            de: "Das Unternehmen ist ein Traditionsversicherer unter dem Dach der Generali-Versicherungsgruppe"
          },
          score: "5"
        }
      }
    }

    trait :with_order_email do
      order_email { "subcompany@example.org" }
    end

    factory :subcompany_gkv do
      company { create(:gkv_company) }
    end
  end
end
