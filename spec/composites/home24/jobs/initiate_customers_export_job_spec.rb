# frozen_string_literal: true

require "rails_helper"
require "composites/home24/jobs/initiate_customers_export_job"

RSpec.describe Home24::Jobs::InitiateCustomersExportJob do
  subject(:job) { described_class.new }

  it { is_expected.to be_a(ApplicationJob) }

  it "should append to the queue 'home24'" do
    expect(subject.queue_name).to eq("home24")
  end

  it "enqueues the job on the 'home24' queue" do
    expect {
      described_class.perform_later
    }.to have_enqueued_job.on_queue("home24")
  end

  it "calls the interactor to initiate customers export " do
    expect(Home24)
      .to receive(:initiate_customers_export)
      .with(max_no_of_customers: nil,
           forced_customer_ids: [])

    described_class.perform_now
  end

  context "when max_no_of_customers is passed" do
    let(:max_no_of_customers) { 1 }

    it "calls the interactor to initiate customers export with max_no_of_customers" do
      expect(Home24)
        .to receive(:initiate_customers_export)
        .with(max_no_of_customers: max_no_of_customers,
              forced_customer_ids: [])

      described_class.perform_now(max_no_of_customers: max_no_of_customers)
    end
  end

  context "when forced_customer_ids is passed" do
    let(:forced_customer_ids) { [1] }

    it "calls the interactor to initiate customers export with forced_customer_ids" do
      expect(Home24)
        .to receive(:initiate_customers_export)
        .with(max_no_of_customers: nil,
              forced_customer_ids: forced_customer_ids)

      described_class.perform_now(forced_customer_ids: forced_customer_ids)
    end
  end
end
