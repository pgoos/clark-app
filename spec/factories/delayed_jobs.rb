# frozen_string_literal: true

FactoryBot.define do
  factory :delayed_job, class: Delayed::Job do
    sequence(:job_id)

    initialize_with do
      handler = OpenStruct.new(job_data: {"job_id" => job_id}).to_yaml
      new(handler: handler)
    end
  end
end
