# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/voucher/interactors/redeem_voucher"

RSpec.describe Customer::Constituents::Voucher::Interactors::RedeemVoucher do
  subject { described_class.new(customer_repo: customer_repo, voucher_repo: voucher_repo) }

  let(:customer_state) { "mandate_customer" }
  let(:voucher) { double :voucher, id: 910, code: "TEST_CODE" }
  let(:customer) {
    double :customer,
           id: 909,
           voucher: nil,
           customer_state: customer_state,
           unredeemed_voucher_code: voucher.code
  }
  let(:customer_repo) { double :repo, find: customer, assign_voucher!: customer }
  let(:voucher_repo) { double :repo, find_by_code: voucher }

  context "when all the validations are correct" do
    it "returns successful result" do
      result = subject.call(customer.id)
      expect(result).to be_successful
    end

    it "returns costumer" do
      expect(customer_repo).to receive(:find).with(customer.id)

      result = subject.call(customer.id)
      expect(result.customer.id).to eq(customer.id)
    end

    it "calls the method to assign voucher on repository" do
      expect(customer_repo).to receive(:assign_voucher!).with(customer.id, voucher.id)
      subject.call(customer.id)
    end

    it "calls the method on repository to check if voucher exists" do
      expect(voucher_repo).to receive(:find_by_code).with(voucher.code)

      subject.call(customer.id)
    end
  end

  context "when customer doesn't exist" do
    let(:customer_repo) { double :repo, find: nil }

    it "returns result with failure" do
      result = subject.call(customer.id)
      expect(result).to be_failure
    end
  end

  context "when customer has already voucher assigned" do
    before do
      allow(customer).to receive(:voucher).and_return(voucher)
    end

    it "returns result with failure" do
      result = subject.call(customer.id)
      expect(result).to be_failure
    end

    it "returns the right error message" do
      result = subject.call(customer.id)
      expect(result.errors).to include I18n.t("composites.customer.constituents.voucher.already_present")
    end
  end

  context "when customer doesn't have unreddemed voucher code" do
    let(:customer) {
      double :customer,
             id: 909,
             voucher: nil,
             customer_state: customer_state,
             unredeemed_voucher_code: nil
    }

    it "returns result with failure" do
      result = subject.call(customer.id)
      expect(result).to be_failure
    end
  end

  context "when customer has not the right customer state" do
    let(:customer) { double :customer, id: 909, voucher: nil, customer_state: "self_service" }

    it "returns result with failure" do
      result = subject.call(customer.id)
      expect(result).to be_failure
    end
  end

  context "when voucher doesn't exists in database" do
    let(:voucher_repo) { double :repo, find_by_code: nil }

    it "returns result with failure" do
      result = subject.call(customer.id)
      expect(result).to be_failure
    end

    it "returns the right error message" do
      result = subject.call(customer.id)
      expect(result.errors).to include I18n.t("composites.customer.constituents.voucher.invalid")
    end
  end
end
