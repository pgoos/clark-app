# == Schema Information
#
# Table name: phones
#
#  id                 :integer          not null, primary key
#  number             :string
#  verification_token :string
#  token_created_at   :datetime
#  verified_at        :datetime
#  primary            :boolean          default(FALSE)
#  mandate_id         :integer
#  created_at         :datetime
#  updated_at         :datetime
#

FactoryBot.define do
  factory :phone do
    number { ClarkFaker::PhoneNumber.phone_number }
    association :mandate
  end
end
