# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/schedule_payback_transaction_request_jobs"

RSpec.describe Payback::Interactors::SchedulePaybackTransactionRequestJobs, :integration do
  subject {
    described_class.new(
      env: environment,
      job: job
    )
  }

  let(:environment) { instance_double(Rails.env, production?: is_production) }
  let(:job) { ApplicationJob }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:payback_transactions) do
    [payback_transaction]
  end

  before do
    allow(job).to receive(:perform_now).and_return(nil)
  end

  describe "#call" do
    context "when arguments contain only one transaction" do
      context "when environment is not production" do
        let(:is_production) { false }

        it "should run job immediately" do
          expect(job).to receive(:perform_now).exactly(:once)

          subject.call(payback_transactions)
        end
      end

      context "when the env is production" do
        let(:is_production) { true }

        it "should schedule the job for later" do
          expect { subject.call(payback_transactions) }
            .to have_enqueued_job(job)
            .with(payback_transaction.id)
            .exactly(:once)
        end
      end
    end

    context "when arguments contain several payback transactions" do
      let(:second_payback_transaction) { build(:payback_transaction_entity, :book, :with_inquiry_category) }
      let(:payback_transactions) { [payback_transaction, second_payback_transaction] }

      context "when environment is not production" do
        let(:is_production) { false }

        it "should run job immediately" do
          expect(job).to receive(:perform_now).exactly(:twice)

          subject.call(payback_transactions)
        end
      end

      context "when the env is production" do
        let(:is_production) { true }

        it "should schedule the job for later" do
          expect { subject.call(payback_transactions) }
            .to have_enqueued_job(job)
            .exactly(:twice)
        end
      end
    end
  end
end
