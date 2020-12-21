# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/handle_refund"

RSpec.describe Payback::Interactors::HandleRefund, :integration do
  subject {
    described_class.new(
      customer_repo: customer_repo,
      process_refund: refund_processor,
      process_refund_black_friday: refund_processor_black_friday
    )
  }

  let(:processed_transactions) { double("Transactions array") }

  let(:refund_processor_result) do
    double(
      Utils::Interactor::Result,
      success?: true,
      failure?: false,
      payback_transactions: processed_transactions
    )
  end

  let(:refund_processor) do
    instance_double(
      Payback::Interactors::ProcessRefund,
      call: refund_processor_result
    )
  end

  let(:refund_processor_black_friday) do
    instance_double(
      Payback::Interactors::ProcessRefundBlackFriday,
      call: refund_processor_result
    )
  end

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer
    )
  end

  let(:customer) { build_stubbed(:customer) }

  describe "#call" do
    context "when payback_transaction given as argument" do
      let(:book_transaction) do
        build(
          :payback_transaction_entity,
          :book,
          :with_inquiry_category
        )
      end

      let(:black_friday_promo) { false }

      before do
        allow(customer_repo).to receive(:find)
          .with(book_transaction.mandate_id)
          .and_return(customer)
        allow(customer).to receive(:black_friday_promo_2020?).and_return(black_friday_promo)
      end

      it "processes refund" do
        expect(refund_processor).to receive(:call).with(book_transaction)
        subject.call(book_transaction)
      end

      it "exposes created payback transaction" do
        result = subject.call(book_transaction)
        expect(result).to be_successful
        expect(result.payback_transactions).to eq(processed_transactions)
      end

      context "when processor returns an error" do
        let(:error) { "some error" }
        let(:refund_processor_result) do
          double(
            Utils::Interactor::Result,
            success?: false,
            failure?: true,
            errors: [error]
          )
        end

        it "returns the error" do
          result = subject.call(book_transaction)
          expect(result).not_to be_successful
          expect(result.errors).to include(error)
        end
      end

      context "when customer is in black friday promo" do
        let(:black_friday_promo) { true }

        it "processes refund with black friday processor" do
          expect(refund_processor_black_friday).to receive(:call).with(book_transaction, customer)
          subject.call(book_transaction)
        end

        it "exposes created payback transaction" do
          result = subject.call(book_transaction)
          expect(result).to be_successful
          expect(result.payback_transactions).to eq(processed_transactions)
        end
      end
    end

    context "when nil given as argument" do
      let(:book_transaction) { nil }

      it "returns not found error" do
        result = subject.call(book_transaction)
        expect(result).not_to be_successful
        expect(result.errors).to include("No book transaction to refund")
      end
    end
  end
end
