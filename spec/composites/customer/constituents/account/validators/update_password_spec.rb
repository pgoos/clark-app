# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/validators/update_password"

RSpec.describe Customer::Constituents::Account::Validators::UpdatePassword do
  subject(:result) { described_class.new.call(password: password) }

  context "when password is blank" do
    let(:password) { "" }

    it "returns an error" do
      expect(result).not_to be_success
      expect(result.errors.to_h[:password]).to include "muss ausgefüllt werden"
    end
  end

  context "when password is not present" do
    subject(:result) { described_class.new.call({}) }

    it "returns an error" do
      expect(result).not_to be_success
      expect(result.errors.to_h[:password]).to include "muss ausgefüllt werden"
    end
  end

  include_examples "password complexity"
end
