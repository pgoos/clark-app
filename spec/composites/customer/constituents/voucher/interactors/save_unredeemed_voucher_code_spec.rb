# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/voucher/interactors/save_unredeemed_voucher_code"

RSpec.describe Customer::Constituents::Voucher::Interactors::SaveUnredeemedVoucherCode do
  subject { described_class.new(customer_repo: customer_repo, voucher_repo: voucher_repo) }

  let(:customer_state) { "self_service" }
  let(:customer) { double :customer, id: 909, voucher: nil, customer_state: customer_state }
  let(:voucher) { double :voucher, id: 910, code: "TEST_CODE" }
  let(:customer_repo) { double :repo, find: customer, save_unredeemed_voucher_code!: customer }
  let(:voucher_repo) { double :repo, find_by_code: voucher, redeemable?: true }

  context "when all the validations are correct" do
    it "returns successful result" do
      result = subject.call(customer.id, voucher.code)
      expect(result).to be_successful
    end

    it "returns costumer" do
      expect(customer_repo).to receive(:find).with(customer.id)

      result = subject.call(customer.id, voucher.code)
      expect(result.customer.id).to eq(customer.id)
    end

    it "calls the method to save code on repository" do
      expect(customer_repo).to receive(:save_unredeemed_voucher_code!).with(customer.id, voucher.code)
      subject.call(customer.id, voucher.code)
    end

    it "calls the method on repository to check if voucher is redeemable" do
      expect(voucher_repo).to receive(:redeemable?).with(voucher.code)

      subject.call(customer.id, voucher.code)
    end
  end

  context "when customer doesn't exist" do
    let(:customer_repo) { double :repo, find: nil }

    it "returns result with failure" do
      result = subject.call(customer.id, voucher.code)
      expect(result).to be_failure
    end
  end

  context "when customer has already voucher assigned" do
    before do
      allow(customer).to receive(:voucher).and_return(voucher)
    end

    it "returns result with failure" do
      result = subject.call(customer.id, voucher.code)
      expect(result).to be_failure
    end

    it "returns the right error message" do
      result = subject.call(customer.id, voucher.code)
      expect(result.errors).to include I18n.t("composites.customer.constituents.voucher.already_present")
    end
  end

  context "when customer has not the right customer state" do
    let(:customer) { double :customer, id: 909, voucher: nil, customer_state: "mandate_customer" }

    it "returns result with failure" do
      result = subject.call(customer.id, voucher.code)
      expect(result).to be_failure
    end
  end

  context "when voucher is not redeemable" do
    let(:voucher_repo) { double :repo, redeemable?: false }

    it "returns result with failure" do
      result = subject.call(customer.id, voucher.code)
      expect(result).to be_failure
    end

    it "returns the right error message" do
      result = subject.call(customer.id, voucher.code)
      expect(result.errors.first.title).to eq I18n.t("composites.customer.constituents.voucher.invalid")
    end
  end
end
