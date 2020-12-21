# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/update_mandate_payback_points"
require "composites/payback/entities/customer"
require "composites/payback/entities/payback_transaction"
require "composites/payback/repositories/customer_repository"
require "composites/payback/repositories/payback_transaction_repository"
require "composites/payback/logger"

RSpec.describe Payback::Interactors::UpdateMandatePaybackPoints, :integration do
  subject { described_class.new(customer_repo: customer_repo, payback_transaction_repo: payback_transaction_repo) }

  let(:points_amount) { 30 }
  let(:operation_name) { :subtract_locked_points }

  let(:customer) do
    build_stubbed(:payback_customer_entity, :accepted, :with_payback_data)
  end

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer,
      subtract_locked_points: customer,
      add_locked_points: customer
    )
  end

  let(:payback_transaction) do
    build_stubbed(
      :payback_transaction_entity,
      :refund,
      :with_inquiry_category,
      points_amount: points_amount,
      state: Payback::Entities::PaybackTransaction::State::RELEASED
    )
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      find: payback_transaction
    )
  end

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
  end

  context "when the payback transaction exists and transaction state is valid" do
    it "expects to call the find method in customer repository" do
      expect(payback_transaction_repo).to receive(:find).with(payback_transaction.id)
      subject.call(payback_transaction.id)
    end

    it "expects to call subtract_locked_points in customer repository" do
      expect(customer_repo).to receive(:subtract_locked_points).with(payback_transaction.mandate_id, points_amount)

      subject.call(payback_transaction.id)
    end

    it "expects result of interactor to be successfully" do
      result = subject.call(payback_transaction.id)
      expect(result).to be_successful
    end
  end

  context "when payback transaction state is locked" do
    let(:payback_transaction) do
      build(
        :payback_transaction_entity,
        :book,
        :with_inquiry_category,
        points_amount: points_amount,
        state: Payback::Entities::PaybackTransaction::State::LOCKED
      )
    end

    it "expects to call the find method in customer repository" do
      expect(payback_transaction_repo).to receive(:find).with(payback_transaction.id)
      subject.call(payback_transaction.id)
    end

    it "expects to call subtract_locked_points in customer repository" do
      expect(customer_repo).to receive(:add_locked_points).with(payback_transaction.mandate_id, points_amount)

      subject.call(payback_transaction.id)
    end

    it "expects result of interactor to be successfully" do
      result = subject.call(payback_transaction.id)
      expect(result).to be_successful
    end
  end

  context "when payback transaction does not exists" do
    before do
      allow(payback_transaction_repo).to receive(:find).and_return(nil)
    end

    it "expects to not call update_points_amount on customer repository" do
      expect(customer_repo).not_to receive(:subtract_locked_points)

      subject.call(payback_transaction.id)
    end

    it "expects interactor result to not be successful" do
      result = subject.call(payback_transaction.id)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(payback_transaction.id)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.payback_transaction_not_found")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(payback_transaction.id)
    end
  end

  context "when payback transaction state is invalid" do
    let(:payback_transaction) do
      build(
        :payback_transaction_entity,
        :refund,
        :with_inquiry_category,
        points_amount: points_amount,
        state: Payback::Entities::PaybackTransaction::State::CREATED
      )
    end

    it "expects to not call update_points_amount on customer repository" do
      expect(customer_repo).not_to receive(:subtract_locked_points)

      subject.call(payback_transaction.id)
    end

    it "expects interactor result to not be successful" do
      result = subject.call(payback_transaction.id)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(payback_transaction.id)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.payback_transaction_wrong_state")
    end
  end
end
