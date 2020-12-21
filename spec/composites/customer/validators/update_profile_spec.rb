# frozen_string_literal: true

require "rails_helper"
require "composites/customer/validators/update_profile"

RSpec.describe Customer::Validators::UpdateProfile do
  subject { described_class.new }

  it "every field is optional" do
    expect(subject.call({})).to be_success
  end

  context "validations" do
    it "gender inclusion" do
      expect(subject).to validate_rule(:gender, :gender_inclusion)
    end

    it "birthdate format" do
      expect(subject).to validate_rule(:birthdate, :date_format)
    end

    it "phone_number format" do
      expect(subject).to validate_rule(:phone_number, :phone_number_format)
    end

    it "zipcode format" do
      expect(subject).to validate_rule(:zipcode, :zipcode_format)
    end

    it "iban format" do
      expect(subject).to validate_rule(:iban, :iban_format)
    end
  end
end
