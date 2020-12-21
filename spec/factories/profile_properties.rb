# == Schema Information
#
# Table name: profile_properties
#
#  id          :integer          not null, primary key
#  identifier  :string
#  name        :string
#  description :string
#  value_type  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :profile_property do
    name { 'Some Property' }
    description { 'Describing this property lightly' }
    value_type { 'Text' }

    trait :yearly_gross_income do
      identifier { "text_brttnkmmn_bad238" }
    end
  end
end
