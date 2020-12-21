# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/handle_cancelled_inquiry_category"

RSpec.describe Payback::Interactors::HandleCancelledInquiryCategory, :integration do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo,
      handle_refund: refund_handler,
      schedule_payback_transaction_request_jobs: scheduler
    )
  }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :refund, :with_inquiry_category)
  end

  let(:processed_transactions) do
    [payback_transaction]
  end

  let(:book_transaction) do
    build(
      :payback_transaction_entity,
      :book,
      :with_inquiry_category,
      state: state,
      info: {
        "effective_date" => Faker::Time.between(from: DateTime.now - 15.days, to: DateTime.now),
        "initial_points_amount" => Payback::Entities::PaybackTransaction::DEFAULT_POINTS_AMOUNT,
        "category_id" => Faker::Number.number(digits: 2),
        "category_name" => Faker::Lorem.characters(number: 10),
        "company_name" => Faker::Lorem.characters(number: 10)
      }
    )
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      find_by_subject: book_transaction
    )
  end

  let(:refund_handler) do
    instance_double(
      Payback::Interactors::ProcessRefund,
      call: refund_handler_result
    )
  end

  let(:refund_handler_result) do
    double(
      Utils::Interactor::Result,
      success?: true,
      failure?: false,
      payback_transactions: processed_transactions
    )
  end

  let(:scheduler) do
    instance_double(
      Payback::Interactors::SchedulePaybackTransactionRequestJobs,
      call: nil
    )
  end

  let(:state) { "locked" }
  let(:inquiry_category_id) { 42 }
  let(:subject_type) { described_class::SUBJECT_TYPE }

  context "when there is suitable book transaction" do
    before do
      allow(payback_transaction_repo).to receive(:find_by_subject)
        .with(inquiry_category_id, subject_type, state)
        .and_return(book_transaction)
    end

    it "processes refund" do
      expect(refund_handler).to receive(:call).with(book_transaction)

      subject.call(inquiry_category_id)
    end

    it "schedules job for all processed transactions" do
      expect(scheduler).to receive(:call).with(processed_transactions)

      subject.call(inquiry_category_id)
    end
  end

  context "when there is no suitable book transaction" do
    before do
      allow(payback_transaction_repo).to receive(:find_by_subject)
        .with(inquiry_category_id, subject_type, state)
        .and_return nil
    end

    it "does not process refund" do
      expect(refund_handler).not_to receive(:call)

      subject.call(inquiry_category_id)
    end

    it "does not schedule jobs" do
      expect(scheduler).not_to receive(:call)

      subject.call(inquiry_category_id)
    end
  end
end
