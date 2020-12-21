# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Phones::Parser do
  subject { described_class.new(phone_number) }

  let(:phone_number) { "1771336274" }

  before { stub_const("DEFAULT_COUNTRY_CODE", :de) }

  describe "#initialize" do
    it "original_number equals to the passed" do
      expect(subject.original_number).to eq(phone_number)
    end

    it "default_country_code equals to the one configured on environment" do
      expect(subject.default_country_code).to eq(DEFAULT_COUNTRY_CODE)
    end

    it "assigns true as default value to enforce_record_country" do
      expect(subject.enforce_record_country).to be_truthy
    end

    it "normalizes number and assigns the value to normalized_number" do
      expect(subject.normalized_number)
        .to eq(TelephoneNumber.parse(phone_number, DEFAULT_COUNTRY_CODE).e164_number)
    end

    context "when enforce_record_country is not enabled" do
      let(:phone_number) { "+431771336274" }

      it "doesn't normalize a number already normalized with different prefix" do
        parser = described_class.new(phone_number, enforce_record_country: false)

        expect(parser.normalized_number).to eq(phone_number)
      end
    end
  end

  describe "#valid?" do
    [
      ClarkFaker::PhoneNumber.phone_number,
      "0#{ClarkFaker::PhoneNumber.phone_number}",
      "+49#{ClarkFaker::PhoneNumber.phone_number}",
      "49#{ClarkFaker::PhoneNumber.phone_number}"
    ].each do |phone|
      it "validates number #{phone} as valid" do
        parser = described_class.new(phone)

        expect(parser).to be_valid
      end
    end

    context "when phone_number is not valid" do
      %w[
        smokeonthewater
        +11525905000
        491525905000123213
        01525905000
        0140745742
        1575790665
        3203336
      ].each do |phone|
        it "doesn't validate number #{phone} as valid" do
          parser = described_class.new(phone)

          expect(parser).not_to be_valid
        end
      end
    end

    context "when enforce_record_country is not enabled" do
      let(:phone_number) { "+15417543010" }

      it "validates number with different prefix" do
        parser = described_class.new(phone_number, enforce_record_country: false)

        expect(parser).to be_valid
      end
    end

    context "when the default country code is AT" do
      before { stub_const("DEFAULT_COUNTRY_CODE", :at) }

      %w[01575790665 1575790665 +431575790665 431575790665].each do |phone|
        it "validates number #{phone} as valid" do
          parser = described_class.new(phone)

          expect(parser).to be_valid
        end
      end

      context "when phone number is not valid" do
        %w[
          smokeonthewater
          +11525905000
          +431575790665123123
          82128342
          3203336
        ].each do |phone|
          it "doesn't validate number #{phone} as valid" do
            parser = described_class.new(phone)

            expect(parser).not_to be_valid
          end
        end
      end
    end
  end
end
