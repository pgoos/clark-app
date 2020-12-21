# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Constituents::Voucher::Repositories::Mappings::Voucher do
  describe ".entity_value" do
    context "when the voucher_id is passed" do
      let(:voucher) { create(:voucher) }

      it "returns voucher entity" do
        value = described_class.entity_value(voucher.id)

        expect(value).to be_kind_of Customer::Constituents::Voucher::Entities::Voucher
      end
    end

    context "when there is no voucher_id" do
      it "returns nil" do
        expect(described_class.entity_value(nil)).to be_nil
      end
    end
  end

  describe ".activerecord_value" do
    context "when there is a voucher passed" do
      let(:voucher) { double(Customer::Constituents::Voucher::Entities::Voucher, id: 1) }

      it "return voucher_id" do
        expect(described_class.activerecord_value(voucher)).to eq voucher.id
      end
    end

    context "when there is no voucher passed" do
      it "return voucher_id" do
        expect(described_class.activerecord_value(nil)).to be_nil
      end
    end
  end
end
