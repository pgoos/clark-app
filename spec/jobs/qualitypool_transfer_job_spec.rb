# frozen_string_literal: true

require "rails_helper"

RSpec.describe QualitypoolTransferJob, :integration, type: :job do
  let(:product) { create(:product) }
  let(:transfer_service_double) { instance_double(Qualitypool::StockTransferService) }
  let(:worker) { Delayed::Worker.new }

  before do
    allow(Qualitypool::StockTransferService).to receive(:new).and_return(transfer_service_double)
    allow(transfer_service_double).to receive(:transfer)
  end

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::DelayedJobAdapter.new
  end

  around do |example|
    old_delay_option = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true

    example.run

    Delayed::Worker.delay_jobs = old_delay_option
  end

  context "when pushing the job in the correct queue" do
    it do
      expect {
        described_class.perform_later(product.id)
      }.to change(Delayed::Job, :count).by(1)
      expect(Delayed::Job.last.delayed_reference).to eq product
    end
  end

  context "with job duplicates" do
    it "ignores the subsequent jobs" do
      expect {
        described_class.perform_later(product.id)
        described_class.perform_later(product.id)
        described_class.perform_later(product.id)
      }.to change(Delayed::Job, :count).by(1)
    end
  end

  context "when executing the job" do
    it "calls the correct service" do
      described_class.perform_now(product.id)
      expect(transfer_service_double).to have_received(:transfer).with(product)
    end
  end

  context "with nil argument" do
    it "does not raise error" do
      expect {
        described_class.perform_later(nil)
      }.to change(Delayed::Job, :count).by(0)
    end
  end

  context "with an empty product" do
    it "does not raise error when enqueuing" do
      expect {
        described_class.perform_later(1)
      }.to change(Delayed::Job, :count).by(0)
    end

    it "does not raise error when performing" do
      job = described_class.perform_later(product.id)
      product.destroy!
      job.perform(product.id)
    end
  end

  context "with a limit on the retry" do
    it "does not exceed the max attempts" do
      allow(transfer_service_double).to receive(:transfer).and_raise("Error")
      described_class.perform_later(product.id)

      job = Delayed::Job.first
      4.times { worker.run(job) }

      expect(job.reload.failed_at).to be_present
    end
  end

  context "when updating metadata" do
    let(:errors) { ["error1"] }
    let(:transfer_error) { Qualitypool::StockTransferError.new(errors: errors) }
    let(:now) { Time.zone.now }

    around do |example|
      Timecop.freeze(now)
      example.run
      Timecop.return
    end

    it "raises an error with an error in the service" do
      allow(transfer_service_double).to receive(:transfer).and_raise(transfer_error)

      described_class.perform_later(product.id)
      job = Delayed::Job.first
      worker.run(job)

      expect(job.reload.metadata["runs"].length).to eq 1
      run = job.reload.metadata["runs"][0]
      expect(run["errors"]).to eq errors
      expect(run["skipped_actions"]).to eq []
      expect(run["actions"]).to eq []
      time = Time.parse(job.reload.metadata["runs"][0]["time"]).iso8601
      expect(time).to eq now.iso8601

      worker.run(job)
      expect(job.reload.metadata["runs"].length).to eq 2
    end
  end

  context "when there is more than one waiting job" do
    let(:product) { create(:product) }
    let!(:jobs) { create_list(:delayed_job, 2, delayed_reference: product, queue: "qualitypool_transfer") }

    it "raises an error" do
      error_message = "Invalid number of concurrent jobs for #{product.id}: #{jobs.map(&:id).sort}"
      expect {
        described_class.perform_later(product)
      }.to raise_error(error_message)
    end
  end

  context "when reenqueuing a job" do
    let(:product) { create(:product) }
    let!(:job) { create(:delayed_job, delayed_reference: product, queue: "qualitypool_transfer") }

    it "reenqueues a failed_at job" do
      job.update!(failed_at: Time.zone.now)
      described_class.perform_later(product)
      expect(job.reload.failed_at).to be_nil
      expect(job.reload.run_at).to be_present
    end

    it "does not reschedule a not failed job" do
      expect {
        described_class.perform_later(product)
      }.not_to change(Delayed::Job, :count)
    end
  end
end
