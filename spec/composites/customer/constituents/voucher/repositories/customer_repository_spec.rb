# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/voucher/repositories/customer_repository"

RSpec.describe Customer::Constituents::Voucher::Repositories::CustomerRepository do
  subject(:repo) { described_class.new }

  let(:voucher) { create(:voucher) }
  let(:unredeemed_voucher_code) { "TEST_CODE" }
  let(:customer_state) { "self_service" }

  let(:mandate) do
    create(
      :mandate,
      info: {
        "unredeemed_voucher_code" => unredeemed_voucher_code
      },
      customer_state: customer_state
    )
  end

  describe "#find" do
    it "returns an entity" do
      customer = repo.find(mandate.id)
      expect(customer).to be_kind_of Customer::Constituents::Voucher::Entities::Customer
      expect(customer.id).not_to be_blank
    end

    context "when customer has unredeemed_voucher code" do
      it "returns returns entity with unredeemed_voucher_code" do
        customer = repo.find(mandate.id)

        expect(customer.unredeemed_voucher_code).to eq unredeemed_voucher_code
      end
    end

    context "when customer has redeemed voucher" do
      let(:mandate) do
        create(
          :mandate,
          customer_state: customer_state,
          voucher: voucher
        )
      end

      it "returns costumer entity containing voucher entity" do
        customer = repo.find(mandate.id)
        expect(customer.voucher).to be_kind_of Customer::Constituents::Voucher::Entities::Voucher
      end
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find(999)).to be_nil
      end
    end
  end

  describe "#save_unredeemed_voucher_code!" do
    let(:voucher_code) { Faker::Lorem.characters(number: 8..15) }
    let(:mandate) { create(:mandate, customer_state: customer_state) }

    before { Timecop.freeze(Time.zone.now) }

    after { Timecop.return }

    it "saves the code under info column" do
      customer = repo.save_unredeemed_voucher_code!(mandate.id, voucher_code)

      expect(customer.unredeemed_voucher_code).to eq voucher_code
      expect(mandate.reload.info["unredeemed_voucher_code"]).to eq voucher_code
    end

    it "saves added time for the voucher" do
      repo.save_unredeemed_voucher_code!(mandate.id, voucher_code)

      expect(mandate.reload.info["voucher"]["added_at"]).to eq(Time.now.to_i)
    end
  end

  describe "#assign_voucher!" do
    let(:voucher) { create(:voucher) }
    let(:mandate) {
      create(
        :mandate,
        customer_state: "mandate_customer",
        state: "accepted",
        info: {
          "unredeemed_voucher_code" => voucher.code
        }
      )
    }

    before { Timecop.freeze(Time.zone.now) }

    after { Timecop.return }

    it "assigns voucher to customer" do
      customer = repo.assign_voucher!(mandate.id, voucher.id)

      expect(customer.voucher.id).to eq(voucher.id)
      expect(mandate.reload.voucher_id).to eq(voucher.id)
    end

    it "saves redeemed time for the voucher" do
      repo.assign_voucher!(mandate.id, voucher.id)

      expect(mandate.reload.info["voucher"]["redeemed_at"]).to eq(Time.now.to_i)
    end

    it "removes unredeemed voucher code" do
      repo.assign_voucher!(mandate.id, voucher.id)

      expect(mandate.reload.info["unredeemed_voucher_code"]).to be_nil
    end
  end
end
