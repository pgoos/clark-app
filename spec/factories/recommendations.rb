# frozen_string_literal: true
# == Schema Information
#
# Table name: recommendations
#
#  id           :integer          not null, primary key
#  mandate_id   :integer
#  category_id  :integer
#  level        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  is_mandatory :boolean          default(FALSE)
#  dismissed    :boolean          default(FALSE)
#

FactoryBot.define do
  factory :recommendation do
    level { "important" }

    mandate factory: :mandate
    category factory: :category

    trait :shallow do
      mandate { nil }
      category { nil }
    end
  end
end
