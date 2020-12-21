# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Entities::Mandate do
  subject { described_class.new(mandate) }

  describe "#requires_iban" do
    subject { super().value_for(:requires_iban) }

    context "when mandate.info['cash_incentive'] is true" do
      let(:mandate) { build(:mandate, info: { "cash_incentive" => true }) }

      it { is_expected.to be(true) }
    end

    context "when mandate has voucher" do
      let(:mandate) { build(:mandate, voucher: voucher) }

      context "when voucher requires_iban is '1'" do
        let(:voucher) { build(:voucher, requires_iban: "1") }

        it { is_expected.to be(true) }
      end

      context "when voucher requires_iban is NOT '1'" do
        let(:voucher) { build(:voucher) }

        it { is_expected.to be(false) }
      end
    end

    context "when mandate.info['cash_incentive'] is NOT present and there is NO voucher" do
      let(:mandate) { build(:mandate) }

      it { is_expected.to be(false) }
    end
  end
end
