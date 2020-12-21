# frozen_string_literal: true
# == Schema Information
#
# Table name: api_partners
#
#  id                :integer          not null, primary key
#  name              :string           default(""), not null
#  secret_key        :string           default(""), not null
#  comments          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  salt              :string
#  consumer_key      :string           default(""), not null
#  partnership_ident :string           default(""), not null
#  access_tokens     :jsonb            not null
#  webhook_base_url  :string           default(""), not null
#

FactoryBot.define do
  factory :api_partner do
    sequence(:name)              { Faker::Name.unique.name }
    sequence(:consumer_key)      { Faker::Crypto.unique.md5 }
    sequence(:partnership_ident) { Faker::Name.unique.name }
  end
end
