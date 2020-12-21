# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/trigger_request_for_transaction"
require "composites/payback/repositories/customer_repository"
require "composites/payback/repositories/payback_transaction_repository"
require "composites/payback/factories/request"
require "composites/payback/outbound/client"

RSpec.describe Payback::Interactors::TriggerRequestForTransaction, :integration do
  subject {
    described_class.new(
      customer_repo: customer_repo,
      payback_transaction_repo: payback_transaction_repo,
      update_customer_payback_points: update_customer_payback_points,
      reschedule_failed_transaction: reschedule_failed_transaction
    )
  }

  let(:inquiry_category) { build(:payback_inquiry_category_entity) }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      find: payback_transaction,
      update!: payback_transaction
    )
  end

  let(:customer) do
    build_stubbed(:payback_customer_entity, :accepted, :with_payback_data)
  end

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer
    )
  end

  let(:request) do
    instance_double(
      Payback::Outbound::Requests::BookPoints,
      call: nil
    )
  end

  let(:update_customer_payback_points) {
    instance_double(
      Payback::Interactors::UpdateMandatePaybackPoints,
      call: nil
    )
  }

  let(:reschedule_failed_transaction) {
    instance_double(
      Payback::Interactors::RescheduleFailedTransaction,
      call: nil
    )
  }

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
    allow(payback_transaction).to receive(:subject).and_return(inquiry_category)
  end

  context "when all the validation are okay" do
    before do
      payback_number = customer.payback_data["paybackNumber"]
      allow(Payback::Factories::Request).to \
        receive(:build).with(payback_transaction, payback_number).and_return(request)
    end

    context "when there is a successful request" do
      let(:locked_until) { DateTime.now }
      let(:points_amount) { 400 }
      let(:attributes_to_update_on_success) { { locked_until: locked_until, points_amount: points_amount } }

      before do
        allow(request).to receive(:response_successful?).and_return(true)
        allow(request)
          .to receive(:attributes_to_be_updated).and_return(attributes_to_update_on_success)

        allow(request).to receive(:response_body).and_return({})
      end

      context "when transaction type is book" do
        it "should send an email to customer" do
          mailer = double("mailer", deliver_later: nil)
          expect(PaybackMailer).to receive(:inquiry_category_added)
            .with(customer.id, payback_transaction.category_name, payback_transaction.points_amount)
            .and_return(mailer)
          expect(mailer).to receive(:deliver_later)

          subject.call(inquiry_category.id)
        end
      end

      context "when transaction type is refund" do
        let(:payback_transaction) do
          build(:payback_transaction_entity, :refund, :with_inquiry_category)
        end

        it "should not send an email to customer" do
          expect(PaybackMailer).not_to receive(:inquiry_category_added)

          subject.call(inquiry_category.id)
        end
      end

      it "should save the state as created and other attributes" do
        attributes_to_save = { state: "locked", info: { response_body: {} } }
        attributes_to_save.merge!(attributes_to_update_on_success)

        expect(payback_transaction_repo).to receive(:update!).with(payback_transaction, attributes_to_save)

        subject.call(payback_transaction.id)
      end

      it "should update customer points" do
        expect(update_customer_payback_points).to receive(:call).with(payback_transaction.id)

        subject.call(payback_transaction.id)
      end

      it "should be result as successfully" do
        result = subject.call(payback_transaction.id)
        expect(result).to be_successful
      end

      it "returns time when request was initiated" do
        request_initiated_at = Time.now + 1.second

        result = Timecop.freeze(request_initiated_at) do
          subject.call(payback_transaction.id)
        end

        expect(result.request_initiated_at).to eq(request_initiated_at)
      end
    end

    context "when the subject is not in rewardable state for booking request" do
      let(:inquiry_category) { build(:payback_inquiry_category_entity, state: "canceled") }

      it "should cancel transaction" do
        expect(payback_transaction_repo).to receive(:update!).with(payback_transaction, state: "canceled")

        subject.call(payback_transaction.id)
      end

      it "should not initiate request" do
        expect(Payback::Factories::Request).not_to receive(:build)

        subject.call(payback_transaction.id)
      end
    end

    context "when the subject is already deleted for booking transaction" do
      before do
        allow(payback_transaction).to receive(:subject).and_return(nil)
      end

      it "should cancel transaction" do
        expect(payback_transaction_repo).to receive(:update!).with(payback_transaction, state: "canceled")

        subject.call(payback_transaction.id)
      end

      it "should not initiate request" do
        expect(Payback::Factories::Request).not_to receive(:build)

        subject.call(payback_transaction.id)
      end
    end

    context "when there is unsuccessful request" do
      before do
        allow(request).to receive(:response_successful?).and_return(false)
        allow(request).to receive(:response_http_code).and_return(401)
        allow(request).to receive(:response_error_code).and_return("TEST_ERROR_CODE")
        Timecop.freeze(Time.now)
      end

      after { Timecop.return }

      it "should save the state as failed and the response_code" do
        attributes_to_save = { state: "failed", response_code: "401[TEST_ERROR_CODE]", info: {} }
        expect(payback_transaction_repo).to receive(:update!)
          .with(payback_transaction, attributes_to_save)

        subject.call(payback_transaction.id)
      end

      it "should not update the payback points for customer" do
        expect(update_customer_payback_points).not_to receive(:call)

        subject.call(payback_transaction.id)
      end

      it "should be result as successfully" do
        result = subject.call(payback_transaction.id)
        expect(result).to be_successful
      end

      it "returns time when request was initiated" do
        result = subject.call(payback_transaction.id)

        expect(result.request_initiated_at).to eq Time.now
      end
    end

    context "when there is successful request but the body is not soap format" do
      let(:unprocessable_response_code) { Payback::Outbound::Requests::Request::UNPROCESSABLE_RESPONSE_CODE }
      let(:not_processable_response_body) { "Dummy respopnse body" }

      before do
        allow(request).to receive(:response_successful?).and_return(false)
        allow(request).to receive(:response_http_code).and_return(200)
        allow(request).to receive(:response_raw_body).and_return(not_processable_response_body)
        allow(request).to receive(:response_error_code).and_return(unprocessable_response_code)
      end

      it "should save the state as failed, the response_code and response body" do
        attributes_to_save = {
          state: "failed",
          response_code: "200[#{unprocessable_response_code}]",
          info: { response_body: not_processable_response_body }
        }
        expect(payback_transaction_repo).to receive(:update!) \
          .with(payback_transaction, attributes_to_save)

        subject.call(payback_transaction.id)
      end

      it "should be interactor result as successful" do
        result = subject.call(payback_transaction.id)
        expect(result).to be_successful
      end
    end

    context "when there is payback number authentication failure" do
      before do
        allow(request).to receive(:response_successful?).and_return(false)
        allow(request).to receive(:response_http_code).and_return(200)
        allow(request)
          .to receive(:response_error_code)
          .and_return(Payback::Outbound::Client::ApiErrorCodes::NUMBER_AUTHENTICATION_FAILED)

        allow(customer_repo).to receive(:save_api_authentication_failure).and_return(true)
      end

      it "saves the api authentication failed to customer" do
        expect(customer_repo).to receive(:save_api_authentication_failure)

        subject.call(payback_transaction.id)
      end
    end

    context "when there is already a failed authentication transaction for customer" do
      let(:customer) do
        build_stubbed(:payback_customer_entity, :accepted, :with_payback_data, paybackAuthenticationFailed: true)
      end

      before do
        allow(customer_repo).to receive(:find).and_return(customer)
      end

      it "saves the api authentication failed to customer" do
        expect(Payback::Factories::Request).not_to receive(:build)

        transaction_info = payback_transaction.info
        transaction_info["automatically_response"] = true

        attributes_to_be_updated = {
          state: Payback::Entities::PaybackTransaction::State::FAILED,
          response_code: "200[#{Payback::Outbound::Client::ApiErrorCodes::NUMBER_AUTHENTICATION_FAILED}]",
          info: transaction_info
        }

        expect(payback_transaction_repo).to receive(:update!).with(payback_transaction, attributes_to_be_updated)

        subject.call(payback_transaction.id)
      end
    end

    context "when request is being initiated for a refund for which mandate doesn't exist" do
      let(:payback_number) { Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX) }

      let(:refund_transaction) do
        build(
          :payback_transaction_entity,
          :refund,
          :with_inquiry_category,
          mandate_id: nil,
          info: {
            "initial_points_amount" => 250,
            "payback_number" => payback_number
          }
        )
      end

      let(:request) do
        instance_double(
          Payback::Outbound::Requests::RefundPoints,
          call: nil
        )
      end

      before do
        allow(payback_transaction_repo).to receive(:find).and_return(refund_transaction)
        allow(customer_repo).to receive(:find).and_return(nil)
        allow(Payback::Factories::Request)
          .to receive(:build).with(refund_transaction, payback_number).and_return(request)
        allow(request).to receive(:response_successful?).and_return(true)
        allow(request).to receive(:attributes_to_be_updated).and_return({})
        allow(request).to receive(:response_body).and_return({})
      end

      it "should save the state as released and other attributes" do
        attributes_to_save = {
          state: "released",
          info: refund_transaction.info.merge(response_body: {})
        }

        expect(payback_transaction_repo).to receive(:update!).with(refund_transaction, attributes_to_save)

        subject.call(refund_transaction.id)
      end

      it "builds request with right payback number" do
        expect(Payback::Factories::Request)
          .to receive(:build).with(refund_transaction, payback_number).and_return(request)

        subject.call(refund_transaction.id)
      end

      it "should not send an email to customer" do
        expect(PaybackMailer).not_to receive(:inquiry_category_added)

        subject.call(inquiry_category.id)
      end

      it "should not update customer points" do
        expect(update_customer_payback_points).not_to receive(:call).with(refund_transaction.id)

        subject.call(refund_transaction.id)
      end

      it "expect to be not successful and including message for missing payback number" do
        allow(refund_transaction).to receive(:info).and_return({})

        result = subject.call(refund_transaction.id)

        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.payback_number_required")
      end

      it "doesn't saves the api authentication failed to customer" do
        allow(request).to receive(:response_successful?).and_return(false)
        allow(request).to receive(:response_http_code).and_return(200)
        allow(request)
          .to receive(:response_error_code)
          .and_return(Payback::Outbound::Client::ApiErrorCodes::NUMBER_AUTHENTICATION_FAILED)

        expect(customer_repo).not_to receive(:save_api_authentication_failure)

        subject.call(refund_transaction.id)
      end
    end
  end

  context "when there are validation errors" do
    let(:not_existing_customer_id) { 999 }
    let(:not_existing_payback_transaction_id) { 999 }

    it "expect to not be successful for not existing transaction" do
      allow(payback_transaction_repo)
        .to receive(:find).with(not_existing_payback_transaction_id, include_subject: true).and_return nil
      result = subject.call(not_existing_payback_transaction_id)

      expect(result).not_to be_successful
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_found")
    end

    it "expect to not be successful for not existing customer " do
      allow(customer_repo).to receive(:find).with(not_existing_customer_id).and_return nil
      allow(payback_transaction).to receive(:mandate_id).and_return(not_existing_payback_transaction_id)

      result = subject.call(payback_transaction.id)

      expect(result).not_to be_successful
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.customer_not_found")
    end

    it "expect to not be successful for transaction that doesn't have initial state" do
      allow(payback_transaction).to receive(:in_initial_state?).and_return false
      result = subject.call(payback_transaction.id)

      expect(result).not_to be_successful
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_allowed")
    end
  end
end
