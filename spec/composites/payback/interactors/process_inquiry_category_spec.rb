# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/process_inquiry_category"

RSpec.describe Payback::Interactors::ProcessInquiryCategory do
  subject {
    described_class.new(
      create_book_transaction: create_book_transaction
    )
  }

  let(:inquiry_category) { build(:payback_inquiry_category_entity) }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
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

  describe "#call" do
    it "creates a payback transaction in initial state with default points amount" do
      expect(create_book_transaction).to receive(:call).with(
        inquiry_category,
        points: Payback::Entities::PaybackTransaction::DEFAULT_POINTS_AMOUNT,
        state: Payback::Entities::PaybackTransaction::INITIAL_STATE
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
        result = subject.call(inquiry_category.id)
        expect(result).not_to be_successful
        expect(result.errors).to include error
      end
    end
  end
end
