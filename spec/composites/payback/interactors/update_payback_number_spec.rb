# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/update_payback_number"
require "composites/payback/entities/customer"
require "composites/payback/repositories/customer_repository"
require "composites/payback/logger"

RSpec.describe Payback::Interactors::UpdatePaybackNumber, :integration do
  subject { described_class.new(customer_repo: customer_repo) }

  let(:customer) do
    instance_double(
      Payback::Entities::Customer,
      id: 1,
      mandate_state: "in_creation",
      payback_enabled: true
    )
  end

  let(:customer_with_payback_data) do
    instance_double(
      Payback::Entities::Customer,
      id: 1,
      payback_enabled: true
    )
  end

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer,
      update_payback_number: customer_with_payback_data,
      payback_number_unique?: true
    )
  end

  let(:valid_payback_number) { "4116995289" }

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
  end

  context "when the customer exists and payback number is valid" do
    it "expects to call the find method in customer repository" do
      expect(customer_repo).to receive(:find).with(customer.id)
      subject.call(customer.id, valid_payback_number)
    end

    it "expects to call update_payback_number in customer repo by adding prefix to number" do
      expect(customer_repo).to \
        receive(:update_payback_number).with(1, described_class::PAYBACK_DE_PREFIX + valid_payback_number)

      subject.call(customer.id, valid_payback_number)
    end

    it "expects result of interactor to be successfully" do
      result = subject.call(customer.id, valid_payback_number)
      expect(result).to be_successful
    end

    it "expects the returned customer to be equal to mocked one" do
      result = subject.call(customer.id, valid_payback_number)
      expect(result.customer).to eq customer_with_payback_data
    end
  end

  context "when the customer doesn't exists" do
    before do
      allow(customer_repo).to receive(:find).with(1).and_return(nil)
    end

    it "expects to not call enable_payback on customer repository" do
      expect(customer_repo).not_to receive(:update_payback_number)
      subject.call(customer.id, valid_payback_number)
    end

    it "expects the interactor result to not be successful" do
      result = subject.call(customer.id, valid_payback_number)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(customer.id, valid_payback_number)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.customer_not_found")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(customer.id, valid_payback_number)
    end
  end

  context "when the payback number is blank" do
    it "expects to not call enable_payback on customer repository" do
      expect(customer_repo).not_to receive(:update_payback_number)
      subject.call(customer.id, "")
    end

    it "expects the interactor result to not be successful" do
      result = subject.call(customer.id, "")
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(customer.id, "")
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.general")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(customer.id, "")
    end
  end

  context "when the payback number is not LUHN valid" do
    let(:not_valid_luhn_number) { "123123" }

    it "expects to not call enable_payback on customer repository" do
      expect(customer_repo).not_to receive(:update_payback_number)
      subject.call(customer.id, not_valid_luhn_number)
    end

    it "expects the interactor result to not be successful" do
      result = subject.call(customer.id, not_valid_luhn_number)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(customer.id, not_valid_luhn_number)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.general")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(customer.id, not_valid_luhn_number)
    end
  end

  context "when the payback number is already taken" do
    before do
      allow(customer_repo).to receive(:payback_number_unique?).and_return false
    end

    it "expects to not call enable_payback on customer repository" do
      expect(customer_repo).not_to receive(:update_payback_number)
      subject.call(customer.id, valid_payback_number)
    end

    it "expects the interactor result to not be successful" do
      result = subject.call(customer.id, valid_payback_number)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(customer.id, valid_payback_number)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.already_taken")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(customer.id, valid_payback_number)
    end
  end

  context "when the mandate is already accepted but has not payback enabled" do
    let(:customer) {
      instance_double(
        Payback::Entities::Customer,
        id: 1,
        mandate_state: "accepted",
        payback_enabled: false
      )
    }

    before do
      allow(customer_repo).to receive(:find).with(1).and_return(customer)
    end

    it "expects to not call update_payback_number on customer repository" do
      expect(customer_repo).not_to receive(:update_payback_number)
      subject.call(customer.id, valid_payback_number)
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(customer.id, valid_payback_number)
    end

    it "expects the request to not be successfully" do
      result = subject.call(customer.id, valid_payback_number)
      expect(result).not_to be_successful
    end

    it "expects to have the error message" do
      result = subject.call(customer.id, valid_payback_number)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_allowed")
    end
  end
end
