# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::Validators::Iban do
  subject { described_class.new(value).call }

  describe "#call" do
    context "iban_valid?" do
      context "when iban is invalid" do
        let(:value) { "invalid iban" }

        it { is_expected.to eq(false) }
      end

      context "when iban is valid" do
        let(:value) { "DE89 3704 0044 0532 0130 00" }

        it { is_expected.to eq(true) }
      end
    end

    describe "iban_country_code_valid?" do
      before do
        allow(Settings).to(
          receive_message_chain("iban.allowed_countries")
            .and_return(allowed_countries)
        )
      end

      let(:value) { "DE89 3704 0044 0532 0130 00" }

      context "when country is allowed" do
        let(:allowed_countries) { { DE: true } }

        it { is_expected.to eq(true) }
      end

      context "when country isn't allowed" do
        let(:allowed_countries) { { FR: true } }

        it { is_expected.to eq(false) }
      end
    end
  end
end
