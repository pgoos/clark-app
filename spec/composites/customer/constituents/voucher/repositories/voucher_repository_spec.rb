# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/voucher/repositories/voucher_repository"

RSpec.describe Customer::Constituents::Voucher::Repositories::VoucherRepository do
  subject(:repo) { described_class.new }

  let(:voucher) { create(:voucher) }

  describe "#find" do
    it "returns an entity" do
      voucher_entity = repo.find(voucher.id)
      expect(voucher_entity).to be_kind_of Customer::Constituents::Voucher::Entities::Voucher
    end

    it "returns entity with the right data from voucher" do
      voucher_entity = repo.find(voucher.id)

      expect(voucher_entity.id).not_to be_blank
      expect(voucher_entity.code).to eq voucher.code
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find(999)).to be_nil
      end
    end
  end

  describe "#find_by_code" do
    it "returns an entity" do
      voucher_entity = repo.find_by_code(voucher.code)
      expect(voucher_entity).to be_kind_of Customer::Constituents::Voucher::Entities::Voucher
    end

    it "returns entity with the right data from voucher" do
      voucher_entity = repo.find_by_code(voucher.code)

      expect(voucher_entity.id).not_to be_blank
      expect(voucher_entity.code).to eq voucher.code
    end

    context "when code does not exist in db" do
      it "returns nil" do
        expect(repo.find_by_code("NOT_EXISTING_CODE")).to be_nil
      end
    end
  end

  describe "#redeemable?" do
    it "return true" do
      expect(repo.redeemable?(voucher.code)).to be_truthy
    end

    context "when voucher doesn't exist" do
      it "returns nil" do
        expect(repo.redeemable?("NOT_EXISTING_CODE")).to be_falsey
      end
    end

    context "when voucher is not redeemable" do
      let(:voucher) { create(:voucher, valid_from: 10.days.from_now) }

      it "returns nil" do
        expect(repo.redeemable?(voucher.code)).to be_falsey
      end
    end
  end
end
