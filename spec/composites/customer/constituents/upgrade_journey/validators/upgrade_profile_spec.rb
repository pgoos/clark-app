# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/upgrade_journey/validators/update_profile"
require "support/validators_matcher"

RSpec.describe Customer::Constituents::UpgradeJourney::Validators::UpdateProfile do
  subject { described_class.new }

  let(:result) { subject.call({}) }
  let(:errors) { subject.errors }

  it "ensures every field is required" do
    expect(result).to be_failure
    expect(result).to be_error(:gender)
    expect(result).to be_error(:first_name)
    expect(result).to be_error(:last_name)
    expect(result).to be_error(:birthdate)
    expect(result).to be_error(:phone_number)
    expect(result).to be_error(:house_number)
    expect(result).to be_error(:zipcode)
    expect(result).to be_error(:city)
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
  end
end
