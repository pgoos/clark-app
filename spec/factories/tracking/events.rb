# frozen_string_literal: true

# == Schema Information
#
# Table name: tracking_events
#
#  id         :uuid             not null, primary key
#  visit_id   :uuid
#  user_id    :integer
#  name       :string
#  properties :jsonb
#  time       :datetime
#  mandate_id :integer
#

FactoryBot.define do
  factory :tracking_event, class: 'Tracking::Event' do
    sequence(:id) { |n| "ab1233a1-1abc-123a-a0ab-12345a1#{ n.to_s.rjust(5, '0') }" }
    sequence(:visit_id) { |n| SecureRandom.uuid }
    name { "some_event" }
  end
end
