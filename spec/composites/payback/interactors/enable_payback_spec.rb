# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/enable_payback"
require "composites/payback/entities/customer"
require "composites/payback/repositories/customer_repository"

RSpec.describe Payback::Interactors::EnablePayback, :integration do
  subject { described_class.new(customer_repo: customer_repo) }

  let(:customer) do
    instance_double(
      Payback::Entities::Customer,
      id: 1,
      mandate_state: "in_creation",
      payback_enabled: false
    )
  end

  let(:customer_with_enabled_payback) do
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
      enable_payback: customer_with_enabled_payback
    )
  end

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
  end

  context "when the customer exists" do
    it "expects to call the find method in customer repository" do
      expect(customer_repo).to receive(:find).with(customer.id)
      subject.call(customer.id)
    end

    it "expects to call the enable_payback method in customer repository" do
      expect(customer_repo).to receive(:enable_payback).with(1)
      subject.call(customer.id)
    end

    it "expects result of interactor to be successfully" do
      result = subject.call(customer.id)
      expect(result).to be_successful
    end

    it "expects the returned customer to have payback enabled flag as true" do
      result = subject.call(customer.id)
      expect(result.customer.payback_enabled).to be_truthy
    end
  end

  context "when the customer doesn't exists" do
    before do
      allow(customer_repo).to receive(:find).with(1).and_return(nil)
    end

    it "expects to not call enable_payback on customer repository" do
      expect(customer_repo).not_to receive(:enable_payback)
      subject.call(customer.id)
    end

    it "expects the interactor result to not be successful" do
      result = subject.call(customer.id)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(customer.id)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.customer_not_found")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(customer.id)
    end
  end

  context "when the customer has accepted mandate state" do
    let(:accepted_customer) do
      instance_double(
        Payback::Entities::Customer,
        id: 2,
        mandate_state: "accepted",
        payback_enabled: false
      )
    end

    before do
      allow(customer_repo).to receive(:find).with(2).and_return(accepted_customer)
    end

    it "expects to not call enable_payback on customer repository" do
      expect(customer_repo).not_to receive(:enable_payback)
      subject.call(accepted_customer.id)
    end

    it "expects the interactor result to not be successful" do
      result = subject.call(accepted_customer.id)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(accepted_customer.id)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.not_allowed")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(accepted_customer.id)
    end
  end

  context "when the customer is payback enabled already" do
    let(:customer) do
      instance_double(
        Payback::Entities::Customer,
        id: 2,
        mandate_state: "accepted",
        payback_enabled: true
      )
    end

    before do
      allow(customer_repo).to receive(:find).with(customer.id).and_return(customer)
    end

    it "expects to not call enable_payback on customer repository" do
      expect(customer_repo).not_to receive(:enable_payback)
      subject.call(customer.id)
    end

    it "expects the interactor result to not successful" do
      result = subject.call(customer.id)
      expect(result).to be_successful
    end
  end
end
