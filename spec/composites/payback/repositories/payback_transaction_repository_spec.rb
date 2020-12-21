# frozen_string_literal: true

require "rails_helper"
require "composites/payback/repositories/payback_transaction_repository"

RSpec.describe Payback::Repositories::PaybackTransactionRepository do
  subject(:repository) { described_class.new }

  describe "#find" do
    let(:book_payback_transaction) {
      create(
        :payback_transaction, :with_inquiry_category, :book
      )
    }

    it "returns entity with aggregated data" do
      payback_transaction = repository.find(book_payback_transaction.id)

      expect(payback_transaction).to be_kind_of Payback::Entities::PaybackTransaction
      expect(payback_transaction.id).to eq(book_payback_transaction.id)
      expect(payback_transaction.subject).to be_nil
    end

    context "when include_subject is passed as true" do
      it "should load subject" do
        payback_transaction = repository.find(book_payback_transaction.id, include_subject: true)

        expect(payback_transaction.subject.id).to eq book_payback_transaction.subject.id
        expect(payback_transaction.subject).to be_kind_of Payback::Entities::InquiryCategory
      end
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repository.find(9999)).to be_nil
      end
    end
  end

  describe "#fetch_subject" do
    context "when subject is InquiryCategory" do
      let(:book_payback_transaction) {
        create(
          :payback_transaction, :with_inquiry_category, :book
        )
      }

      it "should return subject" do
        payback_transaction = repository.find(book_payback_transaction.id)

        subject = repository.fetch_subject(payback_transaction)

        expect(subject).to be_kind_of Payback::Entities::InquiryCategory
        expect(subject.id).to eq book_payback_transaction.subject.id
      end
    end
  end

  describe "#find_locked_booking" do
    let(:locked_booking) {
      create(
        :payback_transaction,
        :with_inquiry_category,
        :book,
        state: Payback::Entities::PaybackTransaction::State::LOCKED
      )
    }

    let(:inquiry_category_id) { locked_booking.subject_id }

    it "returns the relevant payback transaction" do
      transaction = repository.find_locked_booking(inquiry_category_id, InquiryCategory.name)

      expect(transaction).to be_kind_of Payback::Entities::PaybackTransaction
      expect(transaction.subject_id).to eq(inquiry_category_id)
    end

    context "when inquiry_category does not exist" do
      it "returns empty array" do
        expect(repository.find_locked_booking(9999, InquiryCategory.name)).to be_nil
      end
    end
  end

  # rubocop:disable RSpec/PredicateMatcher
  describe "#receipt_no_unique?" do
    let(:receipt_no) { "2284434-1735481-I" }
    let(:existing_payback_transaction) { create(:payback_transaction, :book) }

    context "there is a payback transaction with same receipt_number" do
      it "returns false" do
        allow(PaybackTransaction)
          .to receive(:find_by)
          .with(receipt_no: existing_payback_transaction.receipt_no)
          .and_return(existing_payback_transaction)

        expect(repository.receipt_no_unique?(existing_payback_transaction.receipt_no)).to be_falsy
      end
    end

    context "there is no payback transaction with same receipt_number" do
      it "returns true" do
        allow(PaybackTransaction).to receive(:find_by).with(receipt_no: receipt_no).and_return(nil)
        expect(repository.receipt_no_unique?(receipt_no)).to be_truthy
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe "#create" do
    it "creates a payback transaction" do
      mandate = create(:mandate)
      inquiry = create(:inquiry, mandate: mandate)
      inquiry_category = create(:inquiry_category, inquiry: inquiry)

      attributes = {
        mandate_id: mandate.id,
        subject_id: inquiry_category.id,
        subject_type: "InquiryCategory",
        receipt_no: "1-1-I",
        points_amount: 20,
        locked_until: DateTime.now + 14.days,
        transaction_type: "book",
        state: "created",
        info: {}
      }
      payback_transaction = repository.create(attributes)

      expect(payback_transaction).to be_kind_of Payback::Entities::PaybackTransaction
      expect(payback_transaction.id).to eq PaybackTransaction.find_by(mandate_id: mandate.id).id
    end
  end

  describe "#update" do
    let(:book_payback_transaction) {
      create(
        :payback_transaction, :with_inquiry_category, :book
      )
    }

    it "updates the attributes" do
      attributes_to_update = {
        response_code: "TEST-CODE",
        state: "locked"
      }

      payback_transaction = repository.update!(book_payback_transaction, attributes_to_update)

      expect(payback_transaction).to be_kind_of Payback::Entities::PaybackTransaction
      expect(payback_transaction.response_code).to eq(attributes_to_update[:response_code])
      expect(payback_transaction.state).to eq(attributes_to_update[:state])
    end
  end

  describe "#transactions_marked_to_unlock" do
    let(:time) { DateTime.now }

    let!(:transaction_with_locked_time_ended) {
      create(
        :payback_transaction, :with_inquiry_category, :book, state: :to_unlock, locked_until: time - 3.hours
      )
    }

    let!(:transaction_with_locked_time_in_future) {
      create(
        :payback_transaction, :with_inquiry_category, :book, state: :to_unlock, locked_until: time + 3.hours
      )
    }

    it "should return the marked transactions to unlock that has the value of locked_until before the time" do
      payback_transactions = repository.transactions_marked_to_unlock(time)

      expect(payback_transactions.length).to eq(1)
      expect(payback_transactions[0]).to be_kind_of Payback::Entities::PaybackTransaction
      expect(payback_transactions[0].id).to eq(transaction_with_locked_time_ended.id)
    end
  end

  describe "#find_by_subject" do
    let(:subject_id) { 5 }
    let(:subject_type) { inquiry_category.class.name }
    let(:state) { "locked" }
    let(:inquiry_category) { create :inquiry_category, id: 5 }
    let(:payback_transaction) {
      create(
        :payback_transaction,
        :refund,
        subject_id: subject_id,
        subject_type: subject_type,
        state: state
      )
    }

    it "finds payback transaction with given subject id" do
      payback_transaction
      transaction = repository.find_by_subject(subject_id, subject_type, state)

      expect(transaction).to be_kind_of Payback::Entities::PaybackTransaction
      expect(transaction.subject_id).to eq subject_id
      expect(transaction.subject_type).to eq subject_type
    end

    context "when payback transaction does not exist" do
      it "returns nil" do
        expect(repository.find_by_subject(99, subject_type, state)).to be_nil
      end
    end

    context "when payback transaction has different state" do
      it "returns nil" do
        expect(repository.find_by_subject(subject_id, subject_type, "released")).to be_nil
      end
    end
  end

  describe "#locked_bookings_until" do
    let(:interval) { 24.hours }

    let!(:transaction) {
      create(
        :payback_transaction, :with_inquiry_category, :book, state: :locked,
        locked_until: Time.current + 3.hours
      )
    }

    let!(:transaction_locked_until_after_interval) {
      create(
        :payback_transaction, :with_inquiry_category, :book, state: :locked,
        locked_until: Time.current + interval + 3.hours
      )
    }

    it "should return the marked transactions to refund that has the value of locked_until less than 24 hours" do
      payback_transactions = repository.locked_bookings_until(interval.from_now)

      expect(payback_transactions.length).to eq(1)
      expect(payback_transactions[0]).to be_kind_of Payback::Entities::PaybackTransaction
      expect(payback_transactions[0].id).to eq(transaction.id)
    end
  end

  # rubocop:disable Metrics/BlockLength
  describe "#active_book_transactions" do
    let(:receipt_no) { "TEST_REC_1" }

    let(:mandate) {
      create(
        :mandate,
        :payback_with_data
      )
    }

    context "when there is not any book transaction associated to the customer" do
      it { expect(repository.active_book_transactions(mandate.id)).to be_empty }
    end

    %w[created failed locked to_unlock completed].each do |state|
      context "when there is one book transaction in #{state} state" do
        let!(:payback_transaction) {
          create(
            :payback_transaction,
            :with_inquiry_category,
            :book,
            receipt_no: receipt_no,
            mandate: mandate,
            state: state
          )
        }

        it "should return active transactions for specified mandate_id" do
          payback_transactions = repository.active_book_transactions(mandate.id)

          expect(payback_transactions.length).to eq(1)
          expect(payback_transactions[0]).to be_kind_of Payback::Entities::PaybackTransaction
          expect(payback_transactions[0].id).to eq(payback_transaction.id)
        end

        context "when there is older book transaction in failed state with same receipt no" do
          let!(:failed_payback_transaction) {
            create(
              :payback_transaction,
              :with_inquiry_category,
              :book,
              created_at: payback_transaction.created_at - 1.minute,
              receipt_no: receipt_no,
              mandate: mandate,
              state: :failed
            )
          }

          it "should return active transactions for specified mandate_id" do
            payback_transactions = repository.active_book_transactions(mandate.id)

            expect(payback_transactions.length).to eq(1)
            expect(payback_transactions[0]).to be_kind_of Payback::Entities::PaybackTransaction
            expect(payback_transactions[0].id).to eq(payback_transaction.id)
          end
        end
      end
    end

    %w[canceled refund_initiated].each do |state|
      context "when there is one book transaction in #{state} state" do
        let!(:payback_transaction) {
          create(
            :payback_transaction,
            :with_inquiry_category,
            :book,
            receipt_no: receipt_no,
            mandate: mandate,
            state: state
          )
        }

        it { expect(repository.active_book_transactions(mandate.id)).to be_empty }

        context "when there is older book transaction in failed state with same receipt no" do
          let!(:failed_payback_transaction) {
            create(
              :payback_transaction,
              :with_inquiry_category,
              :book,
              created_at: payback_transaction.created_at - 1.minute,
              receipt_no: receipt_no,
              mandate: mandate,
              state: :failed
            )
          }

          it { expect(repository.active_book_transactions(mandate.id)).to be_empty }
        end
      end
    end
  end

  describe "#active_book_transactions_count" do
    let(:receipt_no) { "TEST_REC_1" }

    let(:mandate) { create(:mandate, :payback_with_data) }

    context "when there is not any book transaction associated to the customer" do
      it { expect(repository.active_book_transactions_count(mandate.id)).to eq(0) }
    end

    %w[created failed locked to_unlock completed].each do |state|
      context "when there is one book transaction in #{state} state" do
        let!(:payback_transaction) {
          create(:payback_transaction, :book, receipt_no: receipt_no, mandate: mandate, state: state)
        }

        it { expect(repository.active_book_transactions_count(mandate.id)).to eq(1) }

        context "when there is another book transaction in failed state with same receipt no" do
          let!(:failed_payback_transaction) {
            create(:payback_transaction, :book, receipt_no: receipt_no, mandate: mandate, state: :failed)
          }

          it { expect(repository.active_book_transactions_count(mandate.id)).to eq(1) }
        end
      end
    end

    %w[canceled refund_initiated].each do |state|
      context "when there is one book transaction in #{state} state" do
        let!(:payback_transaction) {
          create(:payback_transaction, :book, receipt_no: receipt_no, mandate: mandate, state: state)
        }

        it { expect(repository.active_book_transactions_count(mandate.id)).to eq(0) }

        context "when there is another book transaction in failed state with same receipt no" do
          let!(:failed_payback_transaction) {
            create(:payback_transaction, :book, receipt_no: receipt_no, mandate: mandate, state: :failed)
          }

          it { expect(repository.active_book_transactions_count(mandate.id)).to eq(0) }
        end
      end
    end
  end
  # rubocop:enable Metrics/BlockLength

  describe "#failed_transaction_ids" do
    let(:book_receipt_no) { "TEST_REC_1" }

    let!(:failed_transaction) {
      create(
        :payback_transaction, :with_inquiry_category, :book,
        state: :failed,
        locked_until: Time.current + 3.hours,
        receipt_no: book_receipt_no
      )
    }

    context "when there is not any other non-failed retry for the receipt number" do
      it "returns array of failed transaction ids including the one from 'failed_transaction'" do
        ids = repository.failed_transaction_ids

        expect(ids.length).to eq(1)
        expect(ids[0]).to be_kind_of Integer
        expect(ids[0]).to eq(failed_transaction.id)
      end
    end

    Payback::Entities::PaybackTransaction::STATES.values.each do |state|
      context "when there is another non-failed retry for the receipt number in state: #{state}" do
        next if state == Payback::Entities::PaybackTransaction::State::FAILED

        it "excludes corresponding failed transaction id" do
          create(
            :payback_transaction, :with_inquiry_category, :book,
            state: state,
            locked_until: Time.zone.now + 3.hours,
            receipt_no: book_receipt_no,
            retry_order_count: 1
          )

          ids = repository.failed_transaction_ids

          expect(ids.length).to eq(0)
        end
      end
    end
  end

  describe "#revoked_customers_transactions" do
    let(:transaction_state) { Payback::Entities::PaybackTransaction::State::LOCKED }
    let(:revoked_mandate) { create(:mandate, :revoked) }
    let!(:locked_payback_transaction) {
      create(
        :payback_transaction, :with_inquiry_category, :book, state: transaction_state, mandate: revoked_mandate
      )
    }

    it "returns transactions that are in the right state for revoked customers" do
      transactions = repository.revoked_customers_transactions(state: transaction_state)

      expect(transactions.length).to eq(1)
      expect(transactions[0]).to be_kind_of Payback::Entities::PaybackTransaction
      expect(transactions[0].id).to eq(locked_payback_transaction.id)
    end
  end

  describe "#waiting_transactions_for" do
    let(:transaction_state) { Payback::Entities::PaybackTransaction::State::WAITING }
    let(:mandate) { create(:mandate) }
    let!(:waiting_payback_transaction) {
      create(:payback_transaction, :with_inquiry_category, :book, state: transaction_state, mandate: mandate)
    }
    let!(:non_waiting_payback_transaction) {
      create(:payback_transaction, :with_inquiry_category, :book, mandate: mandate)
    }
    let!(:unrelated_waiting_payback_transaction) {
      create(:payback_transaction, :with_inquiry_category, :book, state: transaction_state)
    }

    it "returns transactions that are in the waiting state for given mandate_id" do
      transactions = repository.waiting_transactions_for(mandate.id)

      expect(transactions.length).to eq(1)
      expect(transactions).to include a_kind_of(Payback::Entities::PaybackTransaction)
      expect(transactions).to include an_object_having_attributes(id: waiting_payback_transaction.id)
      expect(transactions).not_to include an_object_having_attributes(id: non_waiting_payback_transaction.id)
      expect(transactions).not_to include an_object_having_attributes(id: unrelated_waiting_payback_transaction.id)
    end
  end

  describe "#waiting_transactions" do
    let(:transaction_state) { Payback::Entities::PaybackTransaction::State::WAITING }
    let!(:waiting_payback_transaction) {
      create(:payback_transaction, :with_inquiry_category, :book, state: transaction_state)
    }
    let!(:non_waiting_payback_transaction) {
      create(:payback_transaction, :with_inquiry_category, :book)
    }

    it "returns transactions that are in the waiting state" do
      transactions = repository.waiting_transactions

      expect(transactions.length).to eq(1)
      expect(transactions).to include a_kind_of(Payback::Entities::PaybackTransaction)
      expect(transactions).to include an_object_having_attributes(id: waiting_payback_transaction.id)
      expect(transactions).not_to include an_object_having_attributes(id: non_waiting_payback_transaction.id)
    end
  end

  describe "#destroy!" do
    context "when transaction exists" do
      let(:payback_transaction) { create(:payback_transaction, :with_inquiry_category, :book) }

      it "returns true and destroys transaction" do
        expect(repository.destroy!(payback_transaction.id)).to be_truthy
        expect(PaybackTransaction.find_by(id: payback_transaction.id)).to be_nil
      end
    end

    context "when transaction does not exists" do
      it "should raise an error" do
        expect {
          repository.destroy!(99)
        }.to raise_error(described_class::Error)
      end
    end
  end

  describe "#with_table_lock" do
    it "should run block within one transaction" do
      expect(ActiveRecord::Base).to receive(:transaction)

      repository.with_table_lock do
        PaybackTransaction.count
      end
    end

    it "should lock the table IN EXCLUSIVE MODE" do
      allow(ActiveRecord::Base).to receive(:transaction).and_yield
      allow(PaybackTransaction).to receive(:count).and_return(0)

      connection = double("Connection")

      expect(ActiveRecord::Base).to receive(:connection) { connection }
      expect(connection).to receive(:execute).with("LOCK TABLE payback_transactions IN EXCLUSIVE MODE")

      repository.with_table_lock do
        PaybackTransaction.count
      end
    end

    it "should yield" do
      expect { |b| repository.with_table_lock(&b) }.to yield_with_no_args
    end
  end
end
