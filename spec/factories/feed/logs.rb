# frozen_string_literal: true

# == Schema Information
#
# Table name: feed_logs
#
#  id          :integer          not null, primary key
#  mandate_id  :integer
#  script_id   :integer
#  from_server :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  text        :text
#  message_id  :string
#  event       :string
#

FactoryBot.define do
  factory :feed_log, class: 'Feed::Log' do
    mandate_id { 1 }
    script_id { 1 }
    from_server { false }
    sequence(:text) { |n| "test text #{n}" }
    message_id { -2 }
  end
end
