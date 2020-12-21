# frozen_string_literal: true

require "rails_helper"
require "composites/payback/jobs/run_sanity_check_job"

RSpec.describe Payback::Jobs::RunSanityCheckJob do
  subject(:job) { described_class.new }

  before do
    allow(Payback).to receive(:run_sanity_check).and_return(double("Utils::Interactor::Result"))
  end

  it { is_expected.to be_a(ApplicationJob) }

  it "should append to the queue 'payback_sanity_check'" do
    expect(subject.queue_name).to eq("payback_sanity_check")
  end

  it "enqueues the job on the 'payback_sanity_check' queue" do
    expect {
      described_class.perform_later
    }.to have_enqueued_job.on_queue("payback_sanity_check")
  end

  it "should call run_sanity_check on Payback interface" do
    expect(Payback).to receive(:run_sanity_check)

    described_class.perform_now
  end
end
