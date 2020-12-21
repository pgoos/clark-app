# frozen_string_literal: true

# == Schema Information
#
# Table name: offer_rules
#
#  id                                 :integer          not null, primary key
#  name                               :string
#  state                              :string           default("inactive")
#  offer_automation_id                :integer
#  category_id                        :integer
#  additional_coverage_feature_idents :string           default([]), is an Array
#  answer_values                      :jsonb
#  plan_idents                        :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  activated                          :boolean          default(FALSE)
#

FactoryBot.define do
  factory :offer_rule do
    name { Faker::Commerce.unique.product_name }
    association :category, factory: :category
    association :offer_automation, factory: :offer_automation

    factory :active_offer_rule do
      after :create do |offer_rule|
        3.times do |i|
          plan = create(:plan, category: offer_rule.category)
          offer_rule.plan_idents[i - 1] = plan.ident
        end
        offer_rule.activate!
      end
    end
  end
end
