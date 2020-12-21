# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/run_sanity_check"
require "composites/payback/repositories/inquiry_category_repository"
require "composites/payback/repositories/customer_repository"
require "composites/payback/entities/customer"

RSpec.describe Payback::Interactors::RunSanityCheck, :integration do
  subject {
    described_class.new(
      inquiry_category_repo: inquiry_category_repo,
      customer_repo: customer_repo
    )
  }

  let(:customer) { build(:payback_customer_entity, :accepted, :with_payback_data) }

  let(:inquiry_category) { build(:payback_inquiry_category_entity) }

  let(:points_amount) {
    Payback::Entities::PaybackTransaction::DEFAULT_POINTS_AMOUNT +
      Payback::Entities::PaybackTransaction::DEFAULT_CAMPAIGN_POINTS_AMOUNT
  }

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      save_sanity_check_result: customer
    )
  end

  let(:inquiry_category_repo) do
    instance_double(
      Payback::Repositories::InquiryCategoryRepository,
      by_customer_created_before: [inquiry_category],
      was_completed?: false
    )
  end

  before do
    allow(::Payback::Logger).to receive(:info).and_return(true)
    allow(customer_repo).to receive(:with_payback_number_in_batches).and_yield([customer])
    allow(customer).to receive(:black_friday_promo_2020?).and_return(false)
  end

  it "calls with_payback_number_in_batches on customer repository" do
    expect(customer_repo).to receive(:with_payback_number_in_batches)

    subject.call
  end

  it "fetches inquiry_categories to calculate expected points amount" do
    expect(inquiry_category_repo)
      .to receive(:by_customer_created_before)
      .with(customer.id, customer.accepted_at + Payback::Entities::Customer::REWARDABLE_PERIOD)

    subject.call
  end

  context "when customer has the right points for one inquiry_category in progress" do
    let(:customer) {
      build(
        :payback_customer_entity,
        :accepted,
        payback_data: {
          "paybackNumber" => Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX),
          "rewardedPoints" => { "locked" => points_amount, "unlocked" => 0 }
        }
      )
    }

    it "saves the sanity check result as true and with right expected amount" do
      expect(customer_repo)
        .to receive(:save_sanity_check_result)
        .with(customer.id, true, points_amount)

      subject.call
    end
  end

  context "when customer doesn't has the right points for one inquiry_category in progress" do
    let(:customer) { build(:payback_customer_entity, :accepted, :with_payback_data) }

    it "saves the sanity check result as false and with right expected amount" do
      expect(customer_repo)
        .to receive(:save_sanity_check_result)
        .with(customer.id, false, points_amount)

      subject.call
    end
  end

  context "when customer has points for cancelled inquiry_category" do
    let(:customer) {
      build(
        :payback_customer_entity,
        :accepted,
        payback_data: {
          "paybackNumber" => Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX),
          "rewardedPoints" => { "locked" => points_amount, "unlocked" => 0 }
        }
      )
    }

    before do
      allow(inquiry_category).to receive(:state).and_return("cancelled")
    end

    it "saves the sanity check result as false and with right expected amount" do
      expect(customer_repo)
        .to receive(:save_sanity_check_result)
        .with(customer.id, false, 0)

      subject.call
    end
  end

  context "when customer has points for cancelled inquiry_category but which was completed before" do
    let(:customer) {
      build(
        :payback_customer_entity,
        :accepted,
        payback_data: {
          "paybackNumber" => Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX),
          "rewardedPoints" => { "locked" => points_amount, "unlocked" => 0 }
        }
      )
    }

    before do
      allow(inquiry_category).to receive(:state).and_return("cancelled")
      allow(inquiry_category_repo).to receive(:was_completed?).with(inquiry_category.id).and_return(true)
    end

    it "saves the sanity check result as true and with right expected amount" do
      expect(customer_repo)
        .to receive(:save_sanity_check_result)
        .with(customer.id, true, points_amount)

      subject.call
    end
  end

  context "when customer has points for in_progress inquiry_category for which inquiry is already canceled" do
    let(:customer) {
      build(
        :payback_customer_entity,
        :accepted,
        payback_data: {
          "paybackNumber" => Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX),
          "rewardedPoints" => { "locked" => points_amount, "unlocked" => 0 }
        }
      )
    }

    before do
      allow(inquiry_category).to receive(:inquiry_state).and_return("canceled")
    end

    it "saves the sanity check result as false and with right expected amount" do
      expect(customer_repo)
        .to receive(:save_sanity_check_result)
        .with(customer.id, false, 0)

      subject.call
    end
  end

  context "when customer was not accepted" do
    before do
      allow(customer).to receive(:accepted_at).and_return(nil)
    end

    it "doesn't fetch inquiry_categories to calculate expected points amount" do
      expect(inquiry_category_repo).not_to receive(:by_customer_created_before)

      subject.call
    end

    it "doesn't update sanity check result for customer" do
      expect(customer_repo).not_to receive(:save_sanity_check_result)

      subject.call
    end
  end

  context "when customer is accepted during black friday promo 2020" do
    before do
      allow(customer).to receive(:black_friday_promo_2020?).and_return(true)
    end

    it "does NOT fetch inquiry_categories to calculate expected points amount" do
      expect(inquiry_category_repo).not_to receive(:by_customer_created_before)

      subject.call
    end

    it "does NOT update sanity check result for customer" do
      expect(customer_repo).not_to receive(:save_sanity_check_result)

      subject.call
    end
  end
end
