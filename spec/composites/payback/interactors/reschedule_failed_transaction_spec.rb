# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/reschedule_failed_transaction"
require "composites/payback/repositories/payback_transaction_repository"

RSpec.describe Payback::Interactors::RescheduleFailedTransaction, :integration do
  subject {
    described_class.new(
      payback_transaction_repo: payback_transaction_repo,
      inquiry_category_repo: inquiry_category_repo
    )
  }

  let(:retry_count) { 0 }
  let(:response_code) { "200[EXTINT-00003]" }

  let(:payback_transaction) do
    build_stubbed(
      :payback_transaction_entity,
      :book,
      :with_inquiry_category,
      retry_order_count: retry_count,
      response_code: response_code,
      state: Payback::Entities::PaybackTransaction::State::FAILED,
      info: {
        "effective_date" => (Time.now - 4.hour).to_s
      }
    )
  end

  let(:payback_transaction_repo) do
    instance_double(
      Payback::Repositories::PaybackTransactionRepository,
      find: payback_transaction,
      create: payback_transaction
    )
  end

  let(:inquiry_category) { build_stubbed(:payback_inquiry_category_entity) }

  let(:inquiry_category_repo) do
    instance_double(
      Payback::Repositories::InquiryCategoryRepository,
      find: inquiry_category
    )
  end

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
    allow(Raven).to receive(:capture_message).and_return(false)
  end

  context "when the transaction exists" do
    context "and has proper response code" do
      it "expects to call the find method in payback transaction repository" do
        expect(payback_transaction_repo).to receive(:find).with(payback_transaction.id)
        subject.call(payback_transaction.id)
      end

      it "expects result of interactor to be successfully" do
        result = subject.call(payback_transaction.id)
        expect(result).to be_successful
      end
    end

    context "and has proper timeout http code" do
      let(:response_code) { "408[]" }

      it "expects to call the find method in payback transaction repository" do
        expect(payback_transaction_repo).to receive(:find).with(payback_transaction.id)
        subject.call(payback_transaction.id)
      end

      it "calls the create method in payback transaction repository with required params" do
        required_attributes = {
          mandate_id: payback_transaction.mandate_id,
          subject_id: payback_transaction.subject_id,
          subject_type: payback_transaction.subject_type,
          transaction_type: payback_transaction.transaction_type,
          receipt_no: payback_transaction.receipt_no,
          points_amount: payback_transaction.points_amount,
          info: payback_transaction.info,
          locked_until: payback_transaction.locked_until,
          parent_transaction_id: payback_transaction.id,
          state: Payback::Entities::PaybackTransaction::State::CREATED,
          retry_order_count: payback_transaction.retry_order_count + 1
        }

        expect(payback_transaction_repo).to receive(:create).with(required_attributes)
        subject.call(payback_transaction.id)
      end

      it "expects result of interactor to be successfully" do
        result = subject.call(payback_transaction.id)
        expect(result).to be_successful
      end
    end

    context "when inquiry category is already canceled" do
      before do
        allow(inquiry_category).to receive(:state).and_return("canceled")
      end

      it "doesn't reschedule transactions" do
        result = subject.call(payback_transaction.id)
        expect(result).not_to be_successful
      end
    end
  end

  context "when the payback_transaction doesn't exists" do
    before do
      allow(payback_transaction_repo).to receive(:find).with(payback_transaction.id).and_return(nil)
    end

    it "expects the interactor result to not be successful" do
      result = subject.call(payback_transaction.id)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(payback_transaction.id)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_found")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(payback_transaction.id)
    end
  end

  context "when the transaction has retry count equal MAX_RETRIES_COUNT or more" do
    let(:retry_count) { Payback::Interactors::RescheduleFailedTransaction::MAX_RETRIES_COUNT }

    it "expects the interactor result to not be successful" do
      result = subject.call(payback_transaction.id)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(payback_transaction.id)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.retry_count_exceeded")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(payback_transaction.id)
    end

    it "expects to notify Sentry for partners" do
      expect(Platform::RavenPartners.instance.sentry_logger).to receive(:capture_message)
      subject.call(payback_transaction.id)
    end

    context "when retry is forced" do
      it "expects interactor result to be successful" do
        result = subject.call(payback_transaction.id, forced_retry_interval: 1.second, retry_forced: true)

        expect(result).to be_successful
      end

      it "creates next transaction" do
        attributes = {
          mandate_id: payback_transaction.mandate_id,
          subject_id: payback_transaction.subject_id,
          subject_type: payback_transaction.subject_type,
          transaction_type: payback_transaction.transaction_type,
          receipt_no: payback_transaction.receipt_no,
          points_amount: payback_transaction.points_amount,
          info: payback_transaction.info,
          locked_until: payback_transaction.locked_until,
          parent_transaction_id: payback_transaction.id,
          state: Payback::Entities::PaybackTransaction::State::CREATED,
          retry_order_count: payback_transaction.retry_order_count + 1
        }

        expect(payback_transaction_repo).to receive(:create).with(attributes)
        subject.call(payback_transaction.id, forced_retry_interval: 1.second, retry_forced: true)
      end
    end

    context "when retry is forced and effective_date is more than 30.days ago" do
      let(:payback_transaction) do
        build_stubbed(
          :payback_transaction_entity,
          :book,
          :with_inquiry_category,
          retry_order_count: retry_count,
          response_code: response_code,
          state: Payback::Entities::PaybackTransaction::State::FAILED,
          info: {
            "effective_date" => 3.months.ago.to_s
          }
        )
      end

      before { Timecop.freeze(Time.now) }

      after { Timecop.return }

      it "creates next transaction, changing effective date and locked_until" do
        info = payback_transaction.info.clone
        info["effective_date"] = Time.now
        locked_until = Time.now + Payback::Entities::PaybackTransaction::DEFAULT_LOCKING_INTERVAL

        attributes = {
          mandate_id: payback_transaction.mandate_id,
          subject_id: payback_transaction.subject_id,
          subject_type: payback_transaction.subject_type,
          transaction_type: payback_transaction.transaction_type,
          receipt_no: payback_transaction.receipt_no,
          points_amount: payback_transaction.points_amount,
          info: info,
          locked_until: locked_until,
          parent_transaction_id: payback_transaction.id,
          state: Payback::Entities::PaybackTransaction::State::CREATED,
          retry_order_count: payback_transaction.retry_order_count + 1
        }

        expect(payback_transaction_repo).to receive(:create).with(attributes)
        subject.call(payback_transaction.id, forced_retry_interval: 1.second, retry_forced: true)
      end
    end
  end

  context "when the transaction has wrong response code" do
    let(:response_code) { "200[wrong-code]" }

    it "expects the interactor result to not be successful" do
      result = subject.call(payback_transaction.id)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(payback_transaction.id)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.wrong_response_code")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(payback_transaction.id)
    end
  end
end
