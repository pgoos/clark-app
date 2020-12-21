# == Schema Information
#
# Table name: ahoy_message_deliveries
#
#  id              :integer          not null, primary key
#  mandrill_id     :string
#  email           :string
#  status          :string
#  reject_reason   :string
#  ahoy_message_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :ahoy_message_delivery, class: 'Ahoy::MessageDelivery' do
    mandrill_id { "MyString" }
    email { "MyString" }
    status { "MyString" }
    reject_reason { "MyString" }
  end
end
