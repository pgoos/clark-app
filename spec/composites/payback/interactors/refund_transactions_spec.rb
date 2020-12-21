# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/refund_transactions"

RSpec.describe Payback::Interactors::RefundTransactions, :integration do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo,
      state_machine: state_machine,
      schedule_payback_transaction_request_jobs: scheduler
    )
  }

  let(:book_transaction) do
    build(
      :payback_transaction_entity,
      :book,
      :with_inquiry_category,
      info: {
        "initial_points_amount" => 250
      }
    )
  end

  let(:refund_transaction) do
    build(
      :payback_transaction_entity,
      :refund,
      :with_inquiry_category
    )
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      locked_bookings_until: locked_bookings,
      update!: book_transaction
    )
  end

  let(:mark_transaction_to_unlock_repo) do
    instance_double(
      Payback::Interactors::MarkTransactionToUnlock,
      call: book_transaction
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

  let(:state_machine) do
    Payback::StateMachines::PaybackTransactionStateMachine
  end

  let(:mailer) { double("mailer", deliver_later: nil) }

  let(:processed_transactions) { [refund_transaction] }

  let(:locked_bookings) { [] }

  let(:payback_transaction_subject) { nil }

  before do
    allow(payback_transaction_repo)
      .to receive(:fetch_subject)
      .with(book_transaction)
      .and_return(payback_transaction_subject)

    allow(Payback::Container).to receive(:resolve).with("interactors.handle_refund").and_return(refund_handler)
  end

  it "gets expiring book transactions" do
    Timecop.freeze do
      expect(payback_transaction_repo).to receive(:locked_bookings_until)
        .with(described_class::INTERVAL_TO_REFUND.from_now)

      subject.call
    end
  end

  context "when there is expiring book transaction" do
    let(:locked_bookings) { [book_transaction] }

    context "when booking transaction subject is completed" do
      let(:payback_transaction_subject) { double("subject", completed?: true) }
      let(:unlock_state) { "unlock_state" }

      before do
        allow(state_machine).to receive(:fire_event!)
          .with(book_transaction.state, :mark_to_unlock)
          .and_return(unlock_state)
      end

      it "does not process refund" do
        expect(refund_handler).not_to receive(:call)

        subject.call
      end

      it "does not schedule job" do
        expect(scheduler).to receive(:call)

        subject.call
      end

      it "does not send email to customer" do
        expect(PaybackMailer).not_to receive(:transaction_refunded)

        subject.call
      end

      it "marks booking transaction to unlock" do
        expect(payback_transaction_repo)
          .to receive(:update!)
          .with(book_transaction, state: unlock_state)
        subject.call
      end
    end

    context "when booking transaction subject is not completed" do
      let(:payback_transaction_subject) { double("subject", completed?: false) }

      it "processes refund" do
        expect(refund_handler).to receive(:call).with(book_transaction)

        subject.call
      end

      it "schedules job for all processed transactions" do
        expect(scheduler).to receive(:call).with(processed_transactions)

        subject.call
      end

      it "sends the email to customer" do
        expect(PaybackMailer).to receive(:transaction_refunded)
          .with(book_transaction.mandate_id, book_transaction.category_name)
          .and_return(mailer)
        expect(mailer).to receive(:deliver_later)

        subject.call
      end

      context "when transaction is not associated to customer" do
        before do
          allow(book_transaction).to receive(:mandate_id).and_return(nil)
        end

        it "does not send email to customer" do
          expect(PaybackMailer).not_to receive(:transaction_refunded)

          subject.call
        end
      end
    end

    context "when booking transaction has no subject" do
      let(:payback_transaction_subject) { nil }

      it "processes refund" do
        expect(refund_handler).to receive(:call).with(book_transaction)

        subject.call
      end

      it "schedules job for all processed transactions" do
        expect(scheduler).to receive(:call).with(processed_transactions)

        subject.call
      end

      it "sends email to customer" do
        expect(PaybackMailer).to receive(:transaction_refunded)
          .with(book_transaction.mandate_id, book_transaction.category_name)
          .and_return(mailer)
        expect(mailer).to receive(:deliver_later)

        subject.call
      end

      context "when transaction is not associated to customer" do
        before do
          allow(book_transaction).to receive(:mandate_id).and_return(nil)
        end

        it "does not send email to customer" do
          expect(PaybackMailer).not_to receive(:transaction_refunded)

          subject.call
        end
      end
    end
  end
end
