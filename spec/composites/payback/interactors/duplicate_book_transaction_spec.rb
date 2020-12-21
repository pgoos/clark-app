# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/duplicate_book_transaction"

RSpec.describe Payback::Interactors::DuplicateBookTransaction do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo
    )
  }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:new_payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      create: new_payback_transaction
    )
  end

  describe "#call" do
    context "when payback transaction is not book" do
      let(:payback_transaction) do
        build(:payback_transaction_entity, :refund, :with_inquiry_category)
      end

      it "returns an error" do
        result = subject.call(payback_transaction)
        expect(result).not_to be_successful
        expect(result.errors).to include "Not book transaction cannot be duplicated"
      end
    end

    context "when receipt_no is unique" do
      before { allow(payback_transaction_repo).to receive(:receipt_no_unique?).and_return(true) }

      it "creates a payback transaction" do
        keys = %i[receipt_no]
        attributes =
          payback_transaction.attributes
                             .except(:id, :created_at, :updated_at, :category_id, :category_name, :company_name)

        expect(payback_transaction_repo).to receive(:create).with(hash_including(*keys, **attributes))

        subject.call(payback_transaction)
      end

      it "exposes created payback transaction" do
        result = subject.call(payback_transaction)
        expect(result.payback_transaction).to eq(new_payback_transaction)
      end

      it "alters receipt_no for created transaction" do
        expect(payback_transaction_repo).to receive(:create)
          .with(
            an_object_satisfying { |attributes|
              attributes[:receipt_no] && attributes[:receipt_no] != payback_transaction.receipt_no
            }
          )

        subject.call(payback_transaction)
      end

      it "overrides passed attributes" do
        overriden_state = "test"

        expect(payback_transaction_repo).to receive(:create)
          .with(hash_including(state: overriden_state))

        subject.call(payback_transaction, state: overriden_state)
      end
    end

    context "when another transaction exists with the same receipt_no" do
      before { allow(payback_transaction_repo).to receive(:receipt_no_unique?).and_return(false) }

      it "returns a duplicate transaction error" do
        result = subject.call(payback_transaction)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.duplicate")
      end
    end
  end
end
