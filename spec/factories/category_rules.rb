# frozen_string_literal: true

# == Schema Information
#
# Table name: categories_rules
#
#  id             :integer       not null, primary key
#  category_ident :string        not null
#  rule_id        :string        not null
#

FactoryBot.define do
  factory :category_rule, class: "Robo::CategoryRule" do
    enabled

    factory :phv_category_rule do
      category_ident { "03b12732" }
      rule_id { "2.1" }
      enabled { true }
    end

    trait :enabled do
      enabled { true }
    end

    trait :disabled do
      enabled { false }
    end
  end
end
