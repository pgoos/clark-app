# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/find_customer"
require "composites/payback/entities/customer"
require "composites/payback/repositories/customer_repository"

RSpec.describe Payback::Interactors::FindCustomer, :integration do
  subject { described_class.new(customer_repo: customer_repo) }

  let(:customer) do
    Payback::Entities::Customer.new(
      id: 1,
      mandate_state: "in_creation",
      payback_data: {},
      payback_enabled: true,
      accepted_at: Time.now
    )
  end

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      find: customer
    )
  end

  before do
    allow(::Payback::Logger).to receive(:error).and_return(true)
  end

  context "when the customer with given id exits" do
    it "expects to call the find method in customer repository" do
      expect(customer_repo).to receive(:find).with(customer.id)
      subject.call(customer.id)
    end

    it "expects result of interactor to be Utils::Interactor::Result instance" do
      result = subject.call(customer.id)
      expect(result).to be_kind_of Utils::Interactor::Result
    end

    it "expects result of interactor to be successfully" do
      result = subject.call(customer.id)
      expect(result).to be_successful
    end

    it "expects the returned customer to be instance of Payback::Entities::Customer" do
      result = subject.call(customer.id)
      expect(result.customer).to be_kind_of Payback::Entities::Customer
    end

    it "expects the id of custmer returned to be same with the one mocked" do
      result = subject.call(customer.id)
      expect(result.customer.id).to eq customer.id
    end
  end

  context "when the customer doesn't exists" do
    let(:not_existing_customer_id) { 999 }

    before do
      allow(customer_repo).to receive(:find).and_return(nil)
    end

    it "expects the interactor result to not be successful" do
      result = subject.call(not_existing_customer_id)
      expect(result).not_to be_successful
    end

    it "expects to include the error message" do
      result = subject.call(not_existing_customer_id)
      expect(result.errors).to include I18n.t("account.wizards.payback.errors.customer_not_found")
    end

    it "expects to log the error" do
      expect(::Payback::Logger).to receive(:error)
      subject.call(not_existing_customer_id)
    end
  end
end
