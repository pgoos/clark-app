# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/try_rescheduling_transactions"
require "composites/payback/interactors/reschedule_failed_transaction"
require "composites/payback/repositories/payback_transaction_repository"

RSpec.describe Payback::Interactors::TryReschedulingTransactions, :integration do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo
    )
  }

  let(:failed_transaction_ids) { [999] }

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      failed_transaction_ids: failed_transaction_ids
    )
  end

  let(:failed_transaction_rescheduler) {
    instance_double(Payback::Interactors::RescheduleFailedTransaction, call: true)
  }

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)

    allow(::Payback::Container)
      .to receive(:resolve)
      .with("interactors.reschedule_failed_transaction")
      .and_return(failed_transaction_rescheduler)
  end

  it "calls the method on payback_repo to fetch failed transaction ids" do
    expect(payback_transaction_repo).to receive(:failed_transaction_ids)

    subject.call
  end

  it "calls the interactor to reschedule transaction" do
    expect(failed_transaction_rescheduler)
      .to receive(:call)
      .with(failed_transaction_ids[0], forced_retry_interval: 1.second, retry_forced: true)

    subject.call
  end
end
