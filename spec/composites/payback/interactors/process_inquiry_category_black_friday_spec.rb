# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/process_inquiry_category_black_friday"

RSpec.describe Payback::Interactors::ProcessInquiryCategoryBlackFriday do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo,
      create_book_transaction: create_book_transaction,
      black_friday_feature_enabled: black_friday_feature_enabled
    )
  }

  let(:inquiry_category) { build(:payback_inquiry_category_entity) }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository
    )
  end

  let(:create_book_transaction) do
    instance_double(
      Payback::Interactors::CreateBookTransaction,
      call: create_book_transaction_result
    )
  end

  let(:create_book_transaction_result) do
    double(
      Utils::Interactor::Result,
      success?: true,
      failure?: false,
      payback_transaction: payback_transaction
    )
  end

  before do
    allow(payback_transaction_repo).to receive(:with_table_lock).and_yield
  end

  describe "#call" do
    context "when feature switch is off" do
      let(:black_friday_feature_enabled) { double("black_friday_feature", call: false) }

      it "returns a black friday feature switch disabled error" do
        result = subject.call(inquiry_category)
        expect(result).not_to be_successful
        expect(result.errors).to include "PAYBACK_BLACK_FRIDAY_PROMO_2020 feature switch is disabled"
      end
    end

    context "when feature switch is on" do
      let(:black_friday_feature_enabled) { double("black_friday_feature", call: true) }

      context "when there is no other active transaction" do
        before do
          allow(payback_transaction_repo).to receive(:active_book_transactions_count)
            .with(inquiry_category.mandate_id)
            .and_return(0)
        end

        it "creates a payback transaction in waiting state with black friday promo 2020 points amount" do
          expect(create_book_transaction).to receive(:call).with(
            inquiry_category,
            points: Payback::Entities::PaybackTransaction::BLACK_FRIDAY_PROMO_POINTS_AMOUNT,
            state: Payback::Entities::PaybackTransaction::State::WAITING,
            lock_table: false
          )
          subject.call(inquiry_category)
        end

        it "exposes array with created payback transaction" do
          result = subject.call(inquiry_category)
          expect(result).to be_successful
          expect(result.payback_transactions).to contain_exactly(payback_transaction)
        end

        context "when create_book_transaction returns error" do
          let(:error) { "Some error" }
          let(:create_book_transaction_result) do
            double(
              Utils::Interactor::Result,
              success?: false,
              failure?: true,
              errors: [error]
            )
          end

          it "returns the error" do
            result = subject.call(inquiry_category)
            expect(result).not_to be_successful
            expect(result.errors).to include error
          end
        end
      end

      context "when there is another active transaction" do
        let(:waiting_transaction) do
          build(
            :payback_transaction_entity,
            :book,
            :with_inquiry_category,
            state: Payback::Entities::PaybackTransaction::State::WAITING
          )
        end
        let(:waiting_transactions) { [waiting_transaction] }

        before do
          allow(payback_transaction_repo).to receive(:active_book_transactions_count)
            .with(inquiry_category.mandate_id)
            .and_return(1)
          allow(payback_transaction_repo).to receive(:waiting_transactions_for)
            .with(inquiry_category.mandate_id)
            .and_return(waiting_transactions)
          allow(payback_transaction_repo).to receive(:update!).and_return(waiting_transaction)
        end

        it "creates a payback transaction in initial state with black friday promo 2020 points amount" do
          expect(create_book_transaction).to receive(:call).with(
            inquiry_category,
            points: Payback::Entities::PaybackTransaction::BLACK_FRIDAY_PROMO_POINTS_AMOUNT,
            state: Payback::Entities::PaybackTransaction::INITIAL_STATE,
            lock_table: false
          )
          subject.call(inquiry_category)
        end

        it "initiates waiting transactions" do
          expect(payback_transaction_repo).to receive(:update!).with(
            waiting_transaction,
            state: Payback::Entities::PaybackTransaction::INITIAL_STATE
          )
          subject.call(inquiry_category)
        end

        it "exposes initiated and created transactions" do
          result = subject.call(inquiry_category)
          expect(result).to be_successful
          expect(result.payback_transactions).to include(payback_transaction, waiting_transaction)
        end

        context "when create_book_transaction returns error" do
          let(:error) { "Some error" }
          let(:create_book_transaction_result) do
            double(
              Utils::Interactor::Result,
              success?: false,
              failure?: true,
              errors: [error]
            )
          end

          it "returns the error" do
            result = subject.call(inquiry_category)
            expect(result).not_to be_successful
            expect(result.errors).to include error
          end
        end
      end
    end
  end
end
