# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/mark_transaction_to_unlock"
require "composites/payback/repositories/payback_transaction_repository"

RSpec.describe Payback::Interactors::MarkTransactionToUnlock, :integration do
  subject { described_class.new(payback_transaction_repo: payback_transaction_repo) }

  describe "#call" do
    let(:payback_transaction) do
      build(
        :payback_transaction_entity,
        :book,
        :with_inquiry_category,
        state: Payback::Entities::PaybackTransaction::State::LOCKED
      )
    end

    let(:payback_transaction_repo) do
      instance_double(
        Payback::Repositories::PaybackTransactionRepository,
        find_locked_booking: payback_transaction
      )
    end

    let(:inquiry_category_id) { payback_transaction.subject_id }
    let(:subject_type) { InquiryCategory.name }

    context "when a valid transaction exists" do
      it "sends a request to update the payback transaction" do
        expect(payback_transaction_repo).to receive(:update!).with(payback_transaction, state: "to_unlock")
        subject.call(inquiry_category_id)
      end
    end

    context "when no valid transaction can be found" do
      let(:invalid_subject_id) { 999 }

      it "returns a not found error" do
        allow(payback_transaction_repo)
          .to receive(:find_locked_booking)
          .with(invalid_subject_id, subject_type)
          .and_return(nil)

        result = subject.call(invalid_subject_id)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_found")
      end
    end

    context "when the transaction is outside of its locked_until period" do
      let(:payback_transaction) do
        build(
          :payback_transaction_entity,
          :book,
          :with_inquiry_category,
          locked_until: Time.zone.now - 1.day,
          state: Payback::Entities::PaybackTransaction::State::LOCKED
        )
      end

      let(:inquiry_category_id) { payback_transaction.subject_id }

      it "does not update the transaction state" do
        allow(payback_transaction_repo)
          .to receive(:find_locked_booking)
          .with(inquiry_category_id, InquiryCategory.name)
          .and_return(payback_transaction)

        result = subject.call(inquiry_category_id)
        expect(result.payback_transaction.state).to eq(payback_transaction.state)
      end
    end
  end
end
