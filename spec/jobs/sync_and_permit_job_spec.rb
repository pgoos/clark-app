# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncAndPermitJob, :delayed_job, :integration, type: :job do
  after do
    allow(Rails.logger).to receive(:info).and_call_original
    allow(Rails.logger).to receive(:error).and_call_original
  end

  context "when running without failure" do
    before do
      allow(Permission).to receive(:sync_and_permit_admins!)
    end

    context "when sync happens" do
      it "syncs and permits" do
        expect(Permission).to receive(:sync_and_permit_admins!)
        subject.perform
      end

      it "logs a message on success" do
        expect(Rails.logger).to receive(:info).with("Performed the sync and permit of admins.")
        subject.perform
      end
    end

    context "when skipped" do
      let(:commit) { `#{described_class::DETECT_COMMIT_CMD}` }

      before do
        create(:async_job_log, message: { "commit" => commit })
      end

      it "does not sync, if a log entry is found" do
        expect(Permission).not_to receive(:sync_and_permit_admins!)
        subject.perform
      end

      it "does not schedule the job, if a log entry is found" do
        expect(SyncAndPermitJob).not_to receive(:perform_later)
        expect(SyncAndPermitJob).not_to receive(:perform_now)
        described_class.schedule_job
      end
    end
  end

  context "when the sync fails" do
    let(:exception) { StandardError.new("Sample exception") }

    before do
      allow(Permission).to receive(:sync_and_permit_admins!).and_raise(exception)
      allow(Raven).to receive(:capture_exception).with(any_args)
    end

    it "does not fail on error" do
      expect { subject.perform }.not_to raise_error
    end

    it "does log the error" do
      expect(Rails.logger).to receive(:error).with("Failed to execute the sync and permissions!").ordered
      expect(Rails.logger).to receive(:error).with(exception).ordered
      subject.perform
    end

    it "sends the error to sentry" do
      expect(Raven).to receive(:capture_exception).with(exception)
      subject.perform
    end
  end
end
