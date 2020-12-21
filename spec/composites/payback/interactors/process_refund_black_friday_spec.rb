# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/process_refund_black_friday"

RSpec.describe Payback::Interactors::ProcessRefundBlackFriday, :integration do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo,
      duplicate_book_transaction: duplicate_book_transaction,
      refund_book_transaction: refund_book_transaction
    )
  }

  let(:customer) { double("customer", id: book_transaction.mandate_id, in_rewardable_period?: false) }

  let(:book_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:refund_transaction) do
    build(:payback_transaction_entity, :refund, :with_inquiry_category)
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      active_book_transactions: locked_transactions_remained,
      update!: locked_transactions_remained
    )
  end

  let(:duplicate_book_transaction) do
    instance_double(
      Payback::Interactors::DuplicateBookTransaction,
      call: nil
    )
  end

  let(:refund_book_transaction) do
    instance_double(
      Payback::Interactors::RefundBookTransaction,
      call: refund_book_transaction_result
    )
  end

  let(:refund_book_transaction_result) do
    double(
      Utils::Interactor::Result,
      success?: true,
      failure?: false,
      payback_transaction: refund_transaction
    )
  end

  let(:locked_transactions_remained) { [] }

  before do
    allow(payback_transaction_repo).to receive(:with_table_lock).and_yield
  end

  describe "#call" do
    it "refunds transaction" do
      expect(refund_book_transaction).to receive(:call).with(book_transaction)
      subject.call(book_transaction, customer)
    end

    it "exposes processed transactions" do
      result = subject.call(book_transaction, customer)
      expect(result).to be_successful
      expect(result.payback_transactions).to eq([refund_transaction])
    end

    context "when there is exactly 1 active transactions remained" do
      let(:second_book_transaction) do
        build(:payback_transaction_entity, :book, :with_inquiry_category, state: second_book_transaction_state)
      end
      let(:locked_transactions_remained) { [second_book_transaction] }

      # rubocop:disable Metrics/BlockLength
      [
        Payback::Entities::PaybackTransaction::State::LOCKED,
        Payback::Entities::PaybackTransaction::State::TO_UNLOCK
      ].each do |state|
        context "when remained transaction in #{state} state" do
          let(:second_book_transaction_state) { state }

          it "refunds both transactions" do
            expect(refund_book_transaction).to receive(:call).with(book_transaction)
            expect(refund_book_transaction).to receive(:call).with(second_book_transaction)
            subject.call(book_transaction, customer)
          end

          it "exposes processed transactions for both book transactions" do
            result = subject.call(book_transaction, customer)
            expect(result).to be_successful
            expect(result.payback_transactions).to eq([refund_transaction, refund_transaction])
          end

          context "when customer is not in rewardable period" do
            before do
              allow(customer).to receive(:in_rewardable_period?).and_return(false)
            end

            it "does not duplicate deactivated transactions in waiting state" do
              expect(duplicate_book_transaction).not_to receive(:call)
            end
          end

          context "when customer is in rewardable period" do
            before do
              allow(customer).to receive(:in_rewardable_period?).and_return(true)
            end

            it "duplicates deactivated transactions in waiting state" do
              expect(duplicate_book_transaction).to receive(:call)
                .with(second_book_transaction, state: Payback::Entities::PaybackTransaction::State::WAITING)

              subject.call(book_transaction, customer)
            end
          end
        end
      end

      [
        Payback::Entities::PaybackTransaction::State::CREATED,
        Payback::Entities::PaybackTransaction::State::FAILED
      ].each do |state|
        context "when remained transaction in #{state} state" do
          let(:second_book_transaction_state) { state }

          it "refunds first book transaction transaction" do
            expect(refund_book_transaction).to receive(:call).with(book_transaction)
            expect(refund_book_transaction).not_to receive(:call).with(second_book_transaction)
            subject.call(book_transaction, customer)
          end

          it "cancels second book transaction" do
            expect(payback_transaction_repo).to receive(:update!)
              .with(second_book_transaction, state: Payback::Entities::PaybackTransaction::State::CANCELED)

            subject.call(book_transaction, customer)
          end

          it "exposes processed transactions for first book transaction" do
            result = subject.call(book_transaction, customer)
            expect(result).to be_successful
            expect(result.payback_transactions).to eq([refund_transaction])
          end

          context "when customer is not in rewardable period" do
            before do
              allow(customer).to receive(:in_rewardable_period?).and_return(false)
            end

            it "does not duplicate deactivated transactions in waiting state" do
              expect(duplicate_book_transaction).not_to receive(:call)
            end
          end

          context "when customer is in rewardable period" do
            before do
              allow(customer).to receive(:in_rewardable_period?).and_return(true)
            end

            it "duplicates deactivated transactions in waiting state" do
              expect(duplicate_book_transaction).to receive(:call)
                .with(second_book_transaction, state: Payback::Entities::PaybackTransaction::State::WAITING)

              subject.call(book_transaction, customer)
            end
          end
        end
      end
      # rubocop:enable Metrics/BlockLength

      context "when remained transaction in completed state" do
        let(:second_book_transaction_state) { Payback::Entities::PaybackTransaction::State::COMPLETED }

        it "refunds first book transaction transaction" do
          expect(refund_book_transaction).to receive(:call).with(book_transaction)
          expect(refund_book_transaction).not_to receive(:call).with(second_book_transaction)
          subject.call(book_transaction, customer)
        end

        it "exposes processed transactions for first book transaction" do
          result = subject.call(book_transaction, customer)
          expect(result).to be_successful
          expect(result.payback_transactions).to eq([refund_transaction])
        end

        context "when customer is not in rewardable period" do
          before do
            allow(customer).to receive(:in_rewardable_period?).and_return(false)
          end

          it "does not duplicate deactivated transactions in waiting state" do
            expect(duplicate_book_transaction).not_to receive(:call)
          end
        end

        context "when customer is in rewardable period" do
          before do
            allow(customer).to receive(:in_rewardable_period?).and_return(true)
          end

          it "does not duplicate deactivated transactions in waiting state" do
            expect(duplicate_book_transaction).not_to receive(:call)
          end
        end
      end
    end

    context "when there are more than 1 active transactions remained" do
      let(:locked_transactions_remained) { [double("transaction"), double("transaction")] }

      it "refunds once" do
        expect(refund_book_transaction).to receive(:call).exactly(:once)
        subject.call(book_transaction, customer)
      end
    end

    context "when there is no active transactions remained" do
      let(:locked_transactions_remained) { [] }

      it "refunds once" do
        expect(refund_book_transaction).to receive(:call).exactly(:once)
        subject.call(book_transaction, customer)
      end
    end

    context "when refund_book_transaction returns an error" do
      let(:error) { "some error" }
      let(:refund_book_transaction_result) do
        double(
          Utils::Interactor::Result,
          success?: false,
          failure?: true,
          errors: [error]
        )
      end

      it "returns the error" do
        result = subject.call(book_transaction, customer)
        expect(result).not_to be_successful
        expect(result.errors).to include(error)
      end
    end
  end
end
