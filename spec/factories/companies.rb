# frozen_string_literal: true
# == Schema Information
#
# Table name: companies
#
#  id                                           :integer          not null, primary key
#  name                                         :string
#  state                                        :string
#  country_code                                 :string
#  logo                                         :string
#  info                                         :hstore
#  created_at                                   :datetime         not null
#  updated_at                                   :datetime         not null
#  national_health_insurance_premium_percentage :decimal(, )
#  average_response_time                        :integer
#  ident                                        :string
#  inquiry_blacklisted                          :boolean          default(FALSE)
#

FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    info {
      {
        info_email: Faker::Internet.email(name: name.parameterize),
        info_phone: "+4915755544949",
        damage_email: "",
        damage_phone: "+4915755544949",
        mandates_email: Faker::Internet.email(name: name.parameterize),
        b2b_contact_info: "",
        mandates_cc_email: ""
      }
    }
    average_response_time { Faker::Number.number(digits: 2) }
    street { "Company street" }
    house_number { "1402" }
    zipcode { "12345" }
    city { "Subcompany Town" }
    country_code { "DE" }

    trait :active do
      state { :active }
    end

    trait :inactive do
      state { :inactive }
    end

    factory :gkv_company do
      national_health_insurance_premium_percentage { 0.3 }
    end
  end
end
