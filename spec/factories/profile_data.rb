# == Schema Information
#
# Table name: profile_data
#
#  id                  :integer          not null, primary key
#  mandate_id          :integer
#  property_identifier :string
#  value               :jsonb
#  source              :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryBot.define do
  factory :profile_datum do
    mandate :factory => :mandate
    property :factory => :profile_property

    trait :yearly_gross_income do
      property factory: %i[profile_property yearly_gross_income]
    end
  end
end
