# == Schema Information
#
# Table name: async_job_logs
#
#  id         :integer          not null, primary key
#  topic_id   :integer
#  topic_type :string
#  severity   :string           not null
#  message    :jsonb            not null
#  job_id     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  job_name   :string
#  queue_name :string
#

FactoryBot.define do
  factory :async_job_log do
    topic { nil }
    severity { "info" }
    sequence(:message) { |n| "{ \"context\" : \"User log message #{n}}\"" }
    job_id { SecureRandom.uuid }
  end
end
