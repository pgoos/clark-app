# frozen_string_literal: true

require "rails_helper"

RSpec.describe SentryJob, :delayed_job, type: :job do
  it "should enqueue to sentry" do
    job = create(:delayed_job)
    Delayed::Worker.lifecycle.run_callbacks(:invoke_job, job) do
      allow(Raven).to receive(:send_event).and_raise("Error")
      expect(Raven).not_to receive(:capture_exception)
      described_class.perform_now("sentry_event")
    end
  end

  it "sanitizes the parameters" do
    perform_enqueued_jobs do
      expect {
        Raven.configuration.async.call("key" => "one", "_aj_symbol_keys" => ["key"])
      }.not_to raise_error
    end
  end

  context "when client class name is passed" do
    let(:class_name) { Platform::RavenPartners.name }
    let(:event) { { event_id: 1 } }

    it "uses passed client" do
      expect(class_name.constantize.instance.raven_client).to receive(:send_event).with(event)

      described_class.perform_now(event, class_name)
    end
  end
end
