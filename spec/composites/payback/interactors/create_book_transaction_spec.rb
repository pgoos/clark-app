# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/create_book_transaction"

RSpec.describe Payback::Interactors::CreateBookTransaction do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo
    )
  }

  let(:points) { 404 }
  let(:state) { Payback::Entities::PaybackTransaction::State::CREATED }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      create: payback_transaction,
      active_book_transactions_count: Payback::Entities::Customer::MAX_BOOK_TRANSACTIONS_COUNT - 1
    )
  end

  before do
    allow(payback_transaction_repo).to receive(:with_table_lock).and_yield
    allow(payback_transaction_repo).to receive(:receipt_no_unique?).and_return(true)
  end

  describe "#call" do
    before { Timecop.freeze }

    after { Timecop.return }

    context "when subject is inquiry_category" do
      let(:inquiry_category) { build(:payback_inquiry_category_entity) }

      context "receipt_no is unique" do
        before { allow(payback_transaction_repo).to receive(:receipt_no_unique?).and_return(true) }

        it "creates a payback transaction" do
          keys = %i[receipt_no]

          attributes = {
            mandate_id: inquiry_category.mandate_id,
            points_amount: points,
            locked_until: DateTime.now + Payback::Entities::PaybackTransaction::DEFAULT_LOCKING_INTERVAL,
            transaction_type: Payback::Entities::PaybackTransaction::TransactionType::BOOK,
            state: state,
            subject_id: inquiry_category.id,
            subject_type: inquiry_category.class.name.split("::").last,
            info: {
              "initial_points_amount" => points,
              "effective_date" => inquiry_category.created_at,
              "company_name" => inquiry_category.company_name,
              "category_id" => inquiry_category.category_id,
              "category_name" => inquiry_category.category_name
            }
          }

          expect(payback_transaction_repo).to receive(:create).with(hash_including(*keys, **attributes))

          result = subject.call(inquiry_category, points: points, state: state)
          expect(result.payback_transaction).to eq(payback_transaction)
        end
      end

      context "when another transaction exists with the same receipt_no" do
        before { allow(payback_transaction_repo).to receive(:receipt_no_unique?).and_return(false) }

        it "returns a duplicate transaction error" do
          result = subject.call(inquiry_category, points: points, state: state)
          expect(result).not_to be_successful
          expect(result.errors).to include I18n.t("account.wizards.payback.errors.duplicate")
        end
      end

      context "when customer has reached maximum number limit of book transactions" do
        before do
          allow(payback_transaction_repo).to receive(:receipt_no_unique?).and_return(true)
          allow(payback_transaction_repo)
            .to receive(:active_book_transactions_count)
            .and_return(Payback::Entities::Customer::MAX_BOOK_TRANSACTIONS_COUNT)
        end

        it "returns a maximum_points_amount_reached error" do
          result = subject.call(inquiry_category, points: points, state: state)

          expect(result).not_to be_successful
          expect(result.errors).to include I18n.t("account.wizards.payback.errors.maximum_points_amount_reached")
        end
      end

      context "when lock_table is not passed" do
        it "should lock table" do
          expect(payback_transaction_repo).to receive(:with_table_lock)

          subject.call(inquiry_category, points: points, state: state)
        end
      end

      context "when lock_table is false" do
        it "should not lock table" do
          expect(payback_transaction_repo).not_to receive(:with_table_lock)

          subject.call(inquiry_category, points: points, state: state, lock_table: false)
        end
      end
    end
  end
end
