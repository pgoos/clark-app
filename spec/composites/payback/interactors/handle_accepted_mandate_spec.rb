# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/handle_accepted_mandate"

RSpec.describe Payback::Interactors::HandleAcceptedMandate, :integration do
  subject {
    described_class.new(
      customer_repo: customer_repo,
      inquiry_category_repo: inquiry_category_repo,
      schedule_payback_transaction_request_jobs: scheduler
    )
  }

  let(:payback_transaction) do
    build(:payback_transaction_entity, :book, :with_inquiry_category)
  end

  let(:customer) { build(:payback_customer_entity, :accepted, :with_payback_data) }

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer
    )
  end

  let(:inquiry_category) { build(:payback_inquiry_category_entity) }

  let(:inquiry_category_repo) do
    instance_double(
      Payback::Repositories::InquiryCategoryRepository,
      find_by_customer: [inquiry_category]
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

  before do
    allow(Payback::Container)
      .to receive(:resolve)
      .with("interactors.process_inquiry_category")
      .and_return(inquiry_category_processor)

    allow(Payback::Container)
      .to receive(:resolve)
      .with("interactors.process_inquiry_category_black_friday")
      .and_return(inquiry_category_processor_black_friday)
  end

  context "when customer has inquiry category" do
    before do
      allow(customer).to receive(:black_friday_promo_2020?).and_return(false)
      allow(inquiry_category_repo).to receive(:find_by_customer)
        .with(customer.id, Payback::Entities::InquiryCategory::PAYBACK_REWARDABLE_STATES)
        .and_return([inquiry_category])
    end

    it "should process inquiry category" do
      expect(inquiry_category_processor).to receive(:call).with(inquiry_category)
      subject.call(customer.id)
    end

    it "should schedule payback transactions" do
      expect(scheduler).to receive(:call).with(payback_transactions)
      subject.call(customer.id)
    end

    context "when customer is in black friday 2020 promo" do
      before do
        allow(customer).to receive(:black_friday_promo_2020?).and_return(true)
      end

      it "should process inquiry category with black friday processor" do
        expect(inquiry_category_processor_black_friday).to receive(:call).with(inquiry_category)
        subject.call(customer.id)
      end
    end

    Payback::Entities::InquiryCategory::NOT_REWARDABLE_CATEGORY_IDENTIFIERS.each do |category_ident|
      context "when the category of inquiry category is #{category_ident}" do
        before do
          allow(inquiry_category).to receive(:category_ident).and_return(category_ident)
        end

        it "should not process inquiry category" do
          expect(inquiry_category_processor).not_to receive(:call)
          subject.call(customer.id)
        end
      end
    end

    context "when the inquiry category state is not eligible for reward" do
      let(:inquiry_category) { build(:payback_inquiry_category_entity, :cancelled) }

      it "should not process inquiry category" do
        expect(inquiry_category_processor).not_to receive(:call)
        subject.call(customer.id)
      end
    end
  end

  context "when customer does not exist" do
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
end
