# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/refund_for_revoked_mandates"
require "composites/payback/repositories/payback_transaction_repository"

RSpec.describe Payback::Interactors::RefundForRevokedMandates, :integration do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo
    )
  }

  let(:customer) { double(id: 99, subject_id: 20) }

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      revoked_customers_transactions: [customer]
    )
  end

  let(:handle_cancelled_inquiry_category_result) do
    double(
      Utils::Interactor::Result,
      success?: true,
      failure?: false
    )
  end

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
    allow(Payback).to receive(:handle_cancelled_inquiry_category).and_return(:handle_cancelled_inquiry_category_result)
  end

  it "calls the method on payback_repo to fetch transactions required to refund" do
    expect(payback_transaction_repo).to receive(:revoked_customers_transactions)

    subject.call
  end

  it "calls the interactor to reschedule transaction" do
    expect(Payback).to receive(:handle_cancelled_inquiry_category).with(customer.subject_id)

    subject.call
  end
end
