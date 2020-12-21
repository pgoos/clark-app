# frozen_string_literal: true

require "rails_helper"

RSpec.describe PushNotificationJob, type: :job do
  let(:mandate_id) { 1 }
  let(:identifier) { "demo" }

  it "enqueues the job" do
    expect {
      described_class.perform_later(mandate_id, identifier)
    }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "enqueues the job on the 'push_notification' queue" do
    expect {
      described_class.perform_later(mandate_id, identifier)
    }.to have_enqueued_job.with(mandate_id, identifier).on_queue("push_notification")
  end
end
