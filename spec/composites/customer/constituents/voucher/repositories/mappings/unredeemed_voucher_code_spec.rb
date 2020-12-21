# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Constituents::Voucher::Repositories::Mappings::UnredeemedVoucherCode do
  describe ".entity_value" do
    context "when there is unredeemed_voucher_code" do
      let(:unredeemed_voucher_code) { "TEST_CODE" }
      let(:info) { { "unredeemed_voucher_code" => unredeemed_voucher_code } }

      it "returns the value of unredeemed_voucher_code" do
        expect(described_class.entity_value(info)).to eq(unredeemed_voucher_code)
      end
    end

    context "when the unredeemed_voucher_code is missing" do
      it "returns nil" do
        expect(described_class.entity_value({})).to be_nil
      end
    end
  end
end
