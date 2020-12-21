# == Schema Information
#
# Table name: comparison_defaults
#
#  id                               :integer          not null, primary key
#  comparison_defaults_container_id :integer
#  name                             :string
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  profile_property_id              :integer
#  value                            :jsonb
#  value_type                       :string
#

FactoryBot.define do
  factory :comparison_default do
    comparison_defaults_container { nil }
    name { "default_value_name" }
    value { {"value" => "some text value"} }
  end
end
