# frozen_string_literal: true

require "rails_helper"
require "composites/payback/jobs/payback_transaction_request_job"
require "composites/payback/interactors/trigger_request_for_transaction"
require "composites/payback/factories/client"

RSpec.describe Payback::Jobs::PaybackTransactionRequestJob do
  subject(:job) { described_class.new(payback_transaction_id) }

  let(:payback_transaction_id) { 1 }
  let(:interactor) { double(call: double(request_initiated_at: Time.now)) }

  before do
    allow(Payback::Interactors::TriggerRequestForTransaction).to receive(:new).and_return(interactor)
  end

  it { is_expected.to be_a(ApplicationJob) }

  it "should append to the queue 'payback_transaction'" do
    expect(subject.queue_name).to eq("payback_transaction")
  end

  it "enqueues the job on the 'payback_transaction' queue" do
    expect {
      described_class.perform_later(payback_transaction_id)
    }.to have_enqueued_job.with(payback_transaction_id).on_queue("payback_transaction")
  end

  context "when the configurations for client are available" do
    before do
      allow(Payback::Factories::Client).to receive(:configurations_available?).and_return(true)
    end

    it "should call interactor to trigger request for transaction" do
      expect(interactor).to receive(:call).with(payback_transaction_id)

      described_class.perform_now(payback_transaction_id)
    end
  end

  context "when the configurations for client are not available" do
    before do
      allow(Payback::Factories::Client).to receive(:configurations_available?).and_return(false)
    end

    it "should not initiate interactor to trigger request for transaction" do
      expect(Payback::Interactors::TriggerRequestForTransaction).not_to receive(:new)

      described_class.perform_now(payback_transaction_id)
    end

    it "reschedules the job on the 'payback_transaction' queue" do
      expect {
        described_class.perform_now(payback_transaction_id)
      }.to have_enqueued_job.with(payback_transaction_id).on_queue("payback_transaction")
    end
  end

  context "when environment is production" do
    let(:interactor) { double(call: double(request_initiated_at: request_initiated_at)) }

    before do
      allow(Payback::Factories::Client).to receive(:configurations_available?).and_return true
      allow(Rails).to receive_message_chain(:env, :production?).and_return true
      Timecop.freeze(Time.now)
    end

    after { Timecop.return }

    context "processing of response takes 1 second" do
      let(:request_initiated_at) { Time.now - 1.second }

      it "should not sleep after request is processed" do
        job = described_class.new
        expect(job)
          .not_to receive(:sleep)

        job.perform(payback_transaction_id)
      end
    end

    context "processing of response takes lees than 1 second" do
      let(:request_initiated_at) { Time.now - 0.1.seconds }

      it "should sleep in order to achieve required time gap between requests" do
        job = described_class.new
        expect(job)
          .to receive(:sleep)
          .with(described_class::REQUIRED_TIME_BETWEEN_REQUESTS.to_f - (Time.now - request_initiated_at))

        job.perform(payback_transaction_id)
      end
    end
  end
end
