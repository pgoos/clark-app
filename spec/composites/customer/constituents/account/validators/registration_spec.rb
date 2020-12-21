# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/validators/registration"

RSpec.describe Customer::Constituents::Account::Validators::Registration do
  subject { described_class.new.call(email: email, password: password) }

  let(:email) { "test@abc.com" }
  let(:password) { "Test1234" }

  context "with valid email and password" do
    it "returns successful result object" do
      expect(subject).to be_success
    end
  end

  context "with invalid email" do
    context "without @ sign" do
      let(:email) { "testabc.com" }

      it "returns email validation error" do
        result = subject
        expect(result).not_to be_success
        expect(result.errors.to_h[:email]).to include(I18n.t("errors.messages.invalid"))
      end
    end

    context "without domain" do
      let(:email) { "test@abc" }

      it "returns email validation error" do
        result = subject
        expect(result).not_to be_success
        expect(result.errors.to_h[:email]).to include(I18n.t("errors.messages.invalid"))
      end
    end
  end

  include_examples "password complexity"
end
