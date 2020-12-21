# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/cleanup_waiting_transactions"

RSpec.describe Payback::Interactors::CleanupWaitingTransactions, :integration do
  subject { described_class.new(payback_transaction_repo: payback_transaction_repo, customer_repo: customer_repo) }

  let(:waiting_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category, state: "waiting")
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      waiting_transactions: [waiting_transaction],
      destroy!: true
    )
  end

  let(:customer) { build(:payback_customer_entity, :accepted, :with_payback_data) }

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer
    )
  end

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
    allow(::Payback::Logger).to receive(:info).and_return(true)
  end

  it "fetches transactions using waiting_transactions method in payback_transaction_repository" do
    expect(payback_transaction_repo).to receive(:waiting_transactions)

    subject.call
  end

  context "when there is not any waiting transaction" do
    before { allow(payback_transaction_repo).to receive(:waiting_transactions).and_return([]) }

    it "interactor result is successful" do
      result = subject.call

      expect(result).to be_successful
    end

    it "doesn't initiate destroy for any transaction" do
      expect(payback_transaction_repo).not_to receive(:destroy!)

      subject.call
    end

    it "logs the required information" do
      expect(Payback::Logger)
        .to receive(:info).with(a_string_matching(/cleanup of waiting transactions started/))
      expect(Payback::Logger)
        .to receive(:info).with(a_string_matching(/cleanup of waiting transactions finished/))

      subject.call
    end
  end

  context "when there is one waiting transaction" do
    context "and customer is in rewardable period" do
      before { allow(customer).to receive(:in_rewardable_period?).and_return(true) }

      it "interactor result is successful" do
        result = subject.call

        expect(result).to be_successful
      end

      it "checks if customer is in rewardable period" do
        expect(customer).to receive(:in_rewardable_period?)

        subject.call
      end

      it "does NOT initiate destroy for the transaction" do
        expect(payback_transaction_repo).not_to receive(:destroy!)

        subject.call
      end

      it "logs the required information" do
        expect(Payback::Logger)
          .to receive(:info).with(a_string_matching(/cleanup of waiting transactions started/))

        expect(Payback::Logger)
          .to receive(:info)
          .with(
            a_string_matching(
              "checking if customer is in_rewardable_period? for transaction - #{waiting_transaction.id}"
            )
          )

        expect(Payback::Logger)
          .to receive(:info).with(a_string_matching(/cleanup of waiting transactions finished/))

        subject.call
      end
    end

    context "and customer is not in rewardable period" do
      before { allow(customer).to receive(:in_rewardable_period?).and_return(false) }

      it "interactor result is successful" do
        result = subject.call

        expect(result).to be_successful
      end

      it "checks if customer is in rewardable period" do
        expect(customer).to receive(:in_rewardable_period?)

        subject.call
      end

      it "initiates destroy for the transaction" do
        expect(payback_transaction_repo).to receive(:destroy!).with(waiting_transaction.id)

        subject.call
      end

      it "logs the required information" do
        expect(Payback::Logger)
          .to receive(:info).with(a_string_matching(/cleanup of waiting transactions started/))
        expect(Payback::Logger)
          .to receive(:info)
          .with(
            a_string_matching(
              "checking if customer is in_rewardable_period? for transaction - #{waiting_transaction.id}"
            )
          )
        expect(Payback::Logger)
          .to receive(:info).with(a_string_matching("destroying transaction - #{waiting_transaction.id}"))
        expect(Payback::Logger).to receive(:info).with(a_string_matching(/cleanup of waiting transactions finished/))

        subject.call
      end

      context "and destroy! on repository raises error" do
        let(:error_message) { "test error" }

        before do
          allow(payback_transaction_repo)
            .to receive(:destroy!)
            .with(waiting_transaction.id)
            .and_raise(Payback::Repositories::PaybackTransactionRepository::Error.new(error_message))
        end

        it "logs the error" do
          expect(Payback::Logger)
            .to receive(:error)
            .with(
              a_string_matching(
                "Waiting transactions cleanup error: TXID #{waiting_transaction.id} - #{error_message}"
              )
            )

          subject.call
        end
      end
    end

    context "and customer associated to transaction is not found" do
      before { allow(customer_repo).to receive(:find).and_return(nil) }

      it "interactor result is successful" do
        result = subject.call

        expect(result).to be_successful
      end

      it "initiates destroy for the transaction" do
        expect(payback_transaction_repo).to receive(:destroy!).with(waiting_transaction.id)

        subject.call
      end

      it "logs the required information" do
        expect(Payback::Logger)
          .to receive(:info).with(a_string_matching(/cleanup of waiting transactions started/))

        expect(Payback::Logger)
          .to receive(:info)
          .with(
            a_string_matching(
              "checking if customer is in_rewardable_period? for transaction - #{waiting_transaction.id}"
            )
          )

        expect(Payback::Logger)
          .to receive(:info).with(a_string_matching("destroying transaction - #{waiting_transaction.id}"))

        expect(Payback::Logger).to receive(:info).with(a_string_matching(/cleanup of waiting transactions finished/))

        subject.call
      end
    end
  end
end
