# == Schema Information
#
# Table name: permissions
#
#  id         :integer          not null, primary key
#  controller :string
#  action     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :permission do
    controller { 'my controller' }
    sequence(:action) { |n| "action#{n}" }

    trait :view_revoked_mandates do
      controller { "admin/mandates/revoked" }
      action { "view" }
    end
  end
end
