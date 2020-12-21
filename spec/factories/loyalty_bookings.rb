# == Schema Information
#
# Table name: loyalty_bookings
#
#  id            :integer          not null, primary key
#  mandate_id    :integer
#  bookable_id   :integer
#  bookable_type :string
#  kind          :integer
#  amount        :integer
#  details       :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :loyalty_booking do
    mandate
    bookable { nil }
    kind { :mam }
    amount { 1 }
  end
end
