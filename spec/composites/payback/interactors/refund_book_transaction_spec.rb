# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/refund_book_transaction"
require "composites/payback/entities/payback_transaction"

RSpec.describe Payback::Interactors::RefundBookTransaction do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo
    )
  }

  let(:book_transaction) do
    build(
      :payback_transaction_entity,
      :book,
      :with_inquiry_category,
      state: transaction_state,
      info: book_transaction_info
    )
  end
  let(:book_transaction_info) do
    {
      "effective_date" => Faker::Time.between(from: DateTime.now - 15.days, to: DateTime.now),
      "initial_points_amount" => 300,
      "category_id" => Faker::Number.number(digits: 2),
      "category_name" => Faker::Lorem.characters(number: 10),
      "company_name" => Faker::Lorem.characters(number: 10)
    }
  end

  let(:transaction_state) do
    Payback::Entities::PaybackTransaction::State::LOCKED
  end

  let(:refund_transaction) do
    build(:payback_transaction_entity, :refund, :with_inquiry_category)
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      create: refund_transaction,
      update!: book_transaction
    )
  end

  describe "#call" do
    context "when passed transaction has book type" do
      let(:transaction) { book_transaction }

      it "updates state of book transaction" do
        expect(payback_transaction_repo).to receive(:update!)
          .with(
            transaction,
            an_object_satisfying { |kwargs| kwargs[:state] != transaction.state }
          )

        subject.call(transaction)
      end

      it "creates refund transaction" do
        attributes = {
          mandate_id: book_transaction.mandate_id,
          receipt_no: book_transaction.refund_receipt_no,
          points_amount: book_transaction.info["initial_points_amount"],
          locked_until: book_transaction.locked_until,
          transaction_type: Payback::Entities::PaybackTransaction::TransactionType::REFUND,
          state: Payback::Entities::PaybackTransaction::INITIAL_STATE,
          subject_id: book_transaction.subject_id,
          subject_type: book_transaction.subject_type,
          info: {
            "original_transaction_date" => book_transaction.effective_date,
            "initial_points_amount" => book_transaction.info["initial_points_amount"],
            "company_name" => book_transaction.info["company_name"],
            "category_id" => book_transaction.info["category_id"],
            "category_name" => book_transaction.info["category_name"]
          }
        }

        expect(payback_transaction_repo).to receive(:create).with(hash_including(**attributes))

        subject.call(transaction)
      end

      it "exposes created payback transaction" do
        result = subject.call(transaction)
        expect(result).to be_successful
        expect(result.payback_transaction).to eq(refund_transaction)
      end

      context "when book transaction is not in valid state" do
        let(:transaction_state) do
          Payback::Entities::PaybackTransaction::State::REFUND_INITIATED
        end

        it "does not create refund transaction" do
          expect(payback_transaction_repo).not_to receive(:create)

          subject.call(transaction)
        end

        it "returns transition error" do
          result = subject.call(transaction)
          expect(result).not_to be_successful
          expect(result.errors).to include a_string_matching(/transition/)
        end
      end
    end

    context "when passed transaction has not book type" do
      let(:transaction) { refund_transaction }

      it "returns not book type error" do
        result = subject.call(transaction)
        expect(result).not_to be_successful
        expect(result.errors).to include("Not book transaction cannot be refunded")
      end
    end
  end
end
