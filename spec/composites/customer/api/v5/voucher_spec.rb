# frozen_string_literal: true

require "rails_helper"

describe Customer::Api::V5::Voucher, :integration, type: :request do
  let(:customer) { create(:customer, :self_service) }
  let(:voucher) { create(:voucher) }

  before do
    allow(Settings).to receive_message_chain(:app_features, :clark2) { true }
  end

  describe "GET /api/customer/voucher" do
    it "returns voucher information about current customer" do
      login_customer(customer, scope: :user)

      json_get_v5 "/api/customer/voucher"

      expect(response.status).to eq 200

      expect(json_response["data"]["id"]).to eq customer.id.to_s
      expect(json_response["data"]["type"]).to eq "customer"
      expect(json_response["data"]["attributes"].keys).to eq %w[
        unredeemedVoucherCode
        redeemedVoucherCode
        voucherRedeemed
      ]
    end
  end

  describe "PATCH /api/customer/voucher" do
    context "when valid params are passed" do
      it "saves unredeemed voucher code and returns it" do
        login_customer(customer, scope: :user)

        json_patch_v5 "/api/customer/voucher", voucher_code: voucher.code

        expect(response.status).to eq 200

        expect(json_response["data"]["id"]).to eq customer.id.to_s
        expect(json_response["data"]["type"]).to eq "customer"
        expect(json_response["data"]["attributes"]["unredeemedVoucherCode"]).to eq voucher.code
      end
    end

    context "when voucher_code is not passed" do
      it "returns 400 status code with error message" do
        login_customer(customer, scope: :user)

        json_patch_v5 "/api/customer/voucher", {}

        expect(response.status).to eq 400
        expect(json_response["errors"].first["code"]).to eq "voucher_code"
      end
    end

    context "when voucher_code is not valid" do
      it "returns 422 status code" do
        login_customer(customer, scope: :user)

        json_patch_v5 "/api/customer/voucher", voucher_code: "NOT_VALID_CODE"

        expect(response.status).to eq 422
      end
    end

    context "when customer has already redeemed voucher" do
      before do
        Mandate.find(customer.id).update(voucher: create(:voucher))
      end

      it "returns 422 status code" do
        login_customer(customer, scope: :user)

        json_patch_v5 "/api/customer/voucher", voucher_code: voucher.code

        expect(response.status).to eq 422
      end
    end
  end
end
