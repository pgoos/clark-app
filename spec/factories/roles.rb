# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  identifier :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  weight     :integer          default(1)
#

FactoryBot.define do
  factory :role do
    identifier { "role_name" }
    name { "Role Name" }

    trait :super_admin do
      identifier { "super_admin" }
      name { "Super Admin" }
    end
  end
end
