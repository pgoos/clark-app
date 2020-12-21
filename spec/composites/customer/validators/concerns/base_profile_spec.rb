# frozen_string_literal: true

require "rails_helper"
require "composites/customer/validators/concerns/base_profile"

RSpec.describe Customer::Validators::BaseProfile do
  subject { dummy.new.call(profile_attributes) }

  let(:dummy) do
    Class.new(Dry::Validation::Contract) do
      include Customer::Validators::BaseProfile

      params do
        optional(:gender).filled(:string)
        optional(:birthdate).filled(:string)
        optional(:phone_number).filled(:string)
        optional(:zipcode).filled(:string)
        optional(:iban).filled(:string)
      end

      rule(:gender).validate(:gender_inclusion)
      rule(:birthdate).validate(:date_format)
      rule(:phone_number).validate(:phone_number_format)
      rule(:zipcode).validate(:zipcode_format)
      rule(:iban).validate(:iban_format)
    end
  end

  let(:profile_attributes) do
    {
      gender: gender,
      birthdate: birthdate,
      phone_number: phone_number,
      zipcode: zipcode,
      iban: iban
    }
  end

  let(:gender) { "female" }
  let(:birthdate) { "07.11.1990" }
  let(:phone_number) { "+491111111111" }
  let(:zipcode) { "60313" }
  let(:iban) { "DE89 3704 0044 0532 0130 00" }

  context "with valid attributes" do
    it "returns successful result object" do
      expect(subject).to be_success
    end
  end

  context "with invalid gender" do
    let(:gender) { "invalid" }

    it "returns gender validation error" do
      result = subject
      expect(result).not_to be_success
      expect(result.errors.to_h[:gender]).to include(I18n.t("errors.messages.inclusion"))
    end
  end

  context "with invalid birthdate" do
    context "when birthdate is an invalid string" do
      let(:birthdate) { "abc" }

      it "returns birthdate validation error" do
        result = subject
        expect(result).not_to be_success
        expect(result.errors.to_h[:birthdate]).to include(I18n.t("errors.messages.invalid"))
      end
    end

    context "when birthdate is more than 130 years ago" do
      let(:birthdate) { 130.years.ago.to_date.to_s }

      it "returns error" do
        result = subject
        expect(result).to be_failure

        msg = I18n.t("activerecord.errors.models.mandate.attributes.birthdate.greater_than")
        expect(result.errors.to_h[:birthdate]).to include(msg)
      end
    end

    context "when birthdate less than 18 years ago" do
      let(:birthdate) { (18.years.ago.to_date + 1.day).to_s }

      it "returns error" do
        result = subject
        expect(result).to be_failure

        msg = I18n.t("activerecord.errors.models.mandate.attributes.birthdate.less_than_or_equal_to")
        expect(result.errors.to_h[:birthdate]).to include(msg)
      end
    end
  end

  context "with invalid phone_number" do
    let(:phone_number) { "+7" }

    it "returns phone_number validation error" do
      result = subject
      expect(result).not_to be_success
      expect(result.errors.to_h[:phone_number]).to include(I18n.t("profile.invalid_phone"))
    end
  end

  context "with invalid zipcode" do
    let(:zipcode) { "123" }

    it "returns zipcode validation error" do
      result = subject
      expect(result).not_to be_success
      expect(result.errors.to_h[:zipcode]).to include(I18n.t("profile.invalid_zipcode"))
    end
  end

  context "with invalid iban" do
    let(:iban) { "abc" }

    it "returns iban validation error" do
      result = subject
      expect(result).not_to be_success
      expect(result.errors.to_h[:iban]).to include(I18n.t("errors.messages.invalid"))
    end
  end
end
