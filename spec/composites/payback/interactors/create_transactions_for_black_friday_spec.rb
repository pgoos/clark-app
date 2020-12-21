# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/create_transactions_for_black_friday"
require "composites/payback/entities/customer"
require "composites/payback/repositories/customer_repository"

RSpec.describe Payback::Interactors::CreateTransactionsForBlackFriday, :integration do
  subject {
    described_class.new(
      customer_repo: customer_repo,
      inquiry_category_repo: inquiry_category_repo,
      black_friday_feature_enabled: black_friday_feature_enabled
    )
  }

  let(:customer) { build(:payback_customer_entity, :accepted, :with_payback_data) }

  let(:inquiry_category_id) { 99 }

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository
    )
  end

  let(:inquiry_category_repo) do
    instance_double(
      Payback::Repositories::InquiryCategoryRepository,
      not_rewarded_ids: [inquiry_category_id]
    )
  end

  let(:handle_inquiry_category_created_result) do
    double(
      Utils::Interactor::Result,
      success?: true,
      failure?: false
    )
  end

  before do
    allow(customer_repo).to receive(:accepted_between_in_batches).and_yield([customer])
    allow(::Payback::Logger).to receive(:error).and_return(true)
    allow(::Payback::Logger).to receive(:info).and_return(true)
    allow(::Payback).to receive(:handle_inquiry_category_created).and_return(handle_inquiry_category_created_result)
  end

  context "when black friday feature switch is disabled" do
    let(:black_friday_feature_enabled) { double("black_friday_feature", call: false) }

    it "returns a black friday feature switch disabled error" do
      result = subject.call

      expect(result).not_to be_successful
      expect(result.errors).to include "PAYBACK_BLACK_FRIDAY_PROMO_2020 is disabled"
    end
  end

  context "when black friday feature switch is enabled" do
    let(:black_friday_feature_enabled) { double("black_friday_feature", call: true) }

    it "fetches accepted customers with the right range" do
      expect(customer_repo)
        .to receive(:accepted_between_in_batches)
        .with(
          Payback::Entities::Customer::BLACK_FRIDAY_PROMO_2020_DATE_RANGE.begin,
          Payback::Entities::Customer::BLACK_FRIDAY_PROMO_2020_DATE_RANGE.end
        )

      subject.call
    end

    it "fetches not rewarded inquiry categories for the right customer" do
      expect(inquiry_category_repo)
        .to receive(:not_rewarded_ids)
        .with(customer.id, Payback::Entities::InquiryCategory::PAYBACK_REWARDABLE_STATES)

      subject.call
    end

    it "calls interactor to handle right inquiry category" do
      expect(Payback).to receive(:handle_inquiry_category_created).with(inquiry_category_id)

      subject.call
    end

    it "logs required information" do
      expect(Payback::Logger)
        .to receive(:info)
        .with(a_string_matching(/Creating of transactions for black friday customers started/))

      expect(Payback::Logger)
        .to receive(:info)
        .with(a_string_matching(/Trying to create transactions for customer #{customer.id}/))

      expect(Payback::Logger)
        .to receive(:info)
        .with(a_string_matching(/Trying to create transaction for inquiry_category #{inquiry_category_id}/))

      expect(Payback::Logger)
        .to receive(:info)
        .with(a_string_matching(/Creating of transactions for black friday customers finished/))

      subject.call
    end
  end
end
