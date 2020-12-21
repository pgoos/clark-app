# frozen_string_literal: true

# == Schema Information
#
# Table name: interactions
#
#  id           :integer          not null, primary key
#  type         :string
#  mandate_id   :integer
#  admin_id     :integer
#  topic_id     :integer
#  topic_type   :string
#  direction    :string
#  content      :text
#  metadata     :jsonb
#  acknowledged :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :interaction_sms, class: "Interaction::Sms" do
    admin
    mandate
    content { Faker::Lorem.characters(number: 640) }
    phone_number { "+49-1590-0933711" }
    direction { :out }
  end
end
