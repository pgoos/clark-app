# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/process_refund"

RSpec.describe Payback::Interactors::ProcessRefund, :integration do
  subject {
    described_class.new(
      refund_book_transaction: refund_book_transaction
    )
  }

  let(:book_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
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

  let(:refund_transaction) { double("refund_transaction") }

  describe "#call" do
    it "refunds transaction" do
      expect(refund_book_transaction).to receive(:call).with(book_transaction)
      subject.call(book_transaction)
    end

    it "exposes processed transactions" do
      result = subject.call(book_transaction)
      expect(result).to be_successful
      expect(result.payback_transactions).to eq([refund_transaction])
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
        result = subject.call(book_transaction)
        expect(result).not_to be_successful
        expect(result.errors).to include(error)
      end
    end
  end
end
