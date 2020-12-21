# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/unlock_transactions"
require "composites/payback/repositories/payback_transaction_repository"

RSpec.describe Payback::Interactors::UnlockTransactions, :integration do
  subject { described_class.new(payback_transaction_repo: payback_transaction_repo, customer_repo: customer_repo) }

  let(:payback_transaction) do
    build(
      :payback_transaction_entity,
      :book,
      :with_inquiry_category,
      state: "to_unlock",
      locked_until: Time.now - 3.hours
    )
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      transactions_marked_to_unlock: [payback_transaction],
      update!: payback_transaction
    )
  end

  let(:customer) {
    build(
      :payback_customer_entity,
      :accepted,
      :with_payback_data,
      rewardedPoints: {"locked" => payback_transaction.points_amount, "unlocked" => 0}
    )
  }

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer,
      unlock_points: customer
    )
  end

  before do
    allow(PaybackMailer).to receive(:send_points_unlocked_email).and_return(true)
  end

  it "should call the transactions_marked_to_unlock in payback transaction repository" do
    expect(payback_transaction_repo).to receive(:transactions_marked_to_unlock)

    subject.call
  end

  it "should call the repo to update the state to 'completed' for payback_transaction" do
    expect(payback_transaction_repo).to receive(:update!).with(payback_transaction, state: "completed")

    subject.call
  end

  it "should unlock points based on the transaction points amount" do
    expect(customer_repo).to receive(:unlock_points).with(customer.id, payback_transaction.points_amount)

    subject.call
  end

  it "sends the points unlocked email" do
    expect(PaybackMailer).to receive(:send_points_unlocked_email)
    subject.call
  end
end
