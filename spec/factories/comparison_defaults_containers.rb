# == Schema Information
#
# Table name: comparison_defaults_containers
#
#  id          :integer          not null, primary key
#  name        :string
#  category_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :comparison_defaults_container do
    category { nil }
    name { 'factory hint: you should add a and use the name of the category' }
  end
end
