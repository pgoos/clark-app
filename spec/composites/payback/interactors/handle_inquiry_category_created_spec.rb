# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/handle_inquiry_category_created"

RSpec.describe Payback::Interactors::HandleInquiryCategoryCreated do
  subject {
    described_class.new(
      customer_repo: customer_repo,
      inquiry_category_repo: inquiry_category_repo,
      process_inquiry_category: inquiry_category_processor,
      process_inquiry_category_black_friday: inquiry_category_processor_black_friday,
      schedule_payback_transaction_request_jobs: scheduler
    )
  }

  let(:inquiry_category) { build(:payback_inquiry_category_entity) }

  let(:inquiry_category_repo) do
    instance_double(
      Payback::Repositories::InquiryCategoryRepository,
      find: inquiry_category
    )
  end

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:customer) { build_stubbed(:payback_customer_entity, :accepted, :with_payback_data) }

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer
    )
  end

  let(:inquiry_category_processor) do
    instance_double(
      Payback::Interactors::ProcessInquiryCategory,
      call: inquiry_category_processor_result
    )
  end

  let(:inquiry_category_processor_black_friday) do
    instance_double(
      Payback::Interactors::ProcessInquiryCategoryBlackFriday,
      call: inquiry_category_processor_result
    )
  end

  let(:inquiry_category_processor_result) do
    double(
      Utils::Interactor::Result,
      success?: true,
      failure?: false,
      payback_transactions: payback_transactions
    )
  end

  let(:payback_transactions) { [payback_transaction] }

  let(:scheduler) do
    instance_double(
      Payback::Interactors::SchedulePaybackTransactionRequestJobs,
      call: nil
    )
  end

  before { allow(customer).to receive(:black_friday_promo_2020?).and_return(false) }

  describe "#call" do
    context "when the inquiry category exists and customer is valid payback customer" do
      before do
        allow(inquiry_category_repo)
          .to receive(:find)
          .with(inquiry_category.id)
          .and_return(inquiry_category)
      end

      it "processes inquiry_category" do
        expect(inquiry_category_processor).to receive(:call).with(inquiry_category)
        subject.call(inquiry_category.id)
      end

      it "schedules payback transaction" do
        expect(scheduler).to receive(:call).with(payback_transactions)
        subject.call(inquiry_category.id)
      end

      context "when customer is in black friday 2020 promo" do
        before { allow(customer).to receive(:black_friday_promo_2020?).and_return(true) }

        it "processes inquiry_category with black friday processor" do
          expect(inquiry_category_processor_black_friday).to receive(:call).with(inquiry_category)
          subject.call(inquiry_category.id)
        end
      end

      context "when inquiry_category_processor returns several payback transactions" do
        let(:second_payback_transaction) do
          build(:payback_transaction_entity, :book, :with_inquiry_category)
        end
        let(:waiting_payback_transaction) do
          build(
            :payback_transaction_entity,
            :book,
            :with_inquiry_category,
            state: Payback::Entities::PaybackTransaction::State::WAITING
          )
        end
        let(:payback_transactions) { [payback_transaction, second_payback_transaction, waiting_payback_transaction] }

        it "schedules a delayed job to be executed for all payback transactions in initial state" do
          expect(scheduler).to receive(:call).with(array_including([payback_transaction, second_payback_transaction]))
          subject.call(customer.id)
        end
      end

      context "when inquiry_category_processor returns error" do
        let(:error) { "Some error" }
        let(:inquiry_category_processor_result) do
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

    context "when the inquiry category does not exist" do
      let(:nonexistent_inquiry_category_id) { 999 }

      before do
        allow(inquiry_category_repo).to receive(:find).with(nonexistent_inquiry_category_id).and_return nil
      end

      it "returns a not found error" do
        result = subject.call(nonexistent_inquiry_category_id)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_found")
      end
    end

    context "when the inquiry category state is not eligible for reward" do
      let(:ineligible_inquiry_category) { build(:payback_inquiry_category_entity, :cancelled) }

      before do
        allow(inquiry_category_repo)
          .to receive(:find)
          .with(ineligible_inquiry_category.id)
          .and_return(ineligible_inquiry_category)
      end

      it "returns a not eligible error" do
        result = subject.call(ineligible_inquiry_category.id)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_eligible")
      end
    end

    context "when customer is does not exist" do
      before do
        allow(customer_repo).to receive(:find).and_return nil
      end

      it "returns a not found error" do
        result = subject.call(inquiry_category.id)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.customer_not_found")
      end
    end

    context "when customer is not accepted" do
      let(:not_accepted_customer) { build_stubbed(:payback_customer_entity) }

      before do
        allow(customer_repo).to receive(:find).and_return(not_accepted_customer)
      end

      it "returns a not allowed error" do
        result = subject.call(inquiry_category.id)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_allowed")
      end
    end

    context "when customer is not a payback customer" do
      before do
        allow(customer).to receive(:payback_enabled).and_return false
      end

      it "returns a not allowed error" do
        result = subject.call(inquiry_category.id)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_allowed")
      end
    end

    context "when customer has not entered their payback number" do
      let(:payback_customer_without_data) { build_stubbed(:payback_customer_entity, :accepted) }

      before do
        allow(customer_repo).to receive(:find).and_return(payback_customer_without_data)
      end

      it "returns a payback number required error" do
        result = subject.call(inquiry_category.id)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.payback_number_required")
      end
    end

    context "when inquiry_category was added outside of the eligible reward period" do
      let(:inquiry_category) {
        build(
          :payback_inquiry_category_entity,
          created_at: customer.accepted_at + (Payback::Entities::Customer::REWARDABLE_PERIOD + 1.day)
        )
      }

      it "returns a not eligible error" do
        result = subject.call(inquiry_category.id)
        expect(result).not_to be_successful
        expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_eligible")
      end
    end

    Payback::Entities::InquiryCategory::NOT_REWARDABLE_CATEGORY_IDENTIFIERS.each do |category_ident|
      context "when the category of inquiry_category is #{category_ident}" do
        before do
          allow(inquiry_category).to receive(:category_ident).and_return(category_ident)
        end

        it "returns a not eligible error" do
          result = subject.call(inquiry_category.id)

          expect(result).not_to be_successful
          expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_eligible")
        end
      end
    end
  end
end
