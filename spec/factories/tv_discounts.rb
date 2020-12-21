# frozen_string_literal: true

# == Schema Information
#
# Table name: tv_discounts
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  discount   :float            not null
#  start      :datetime         not null
#  end        :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :tv_discount do
    name { "tv discount" }
    discount { 0 }
    start { Time.zone.now }
    self.end { Time.zone.now + 1.year }
  end
end
