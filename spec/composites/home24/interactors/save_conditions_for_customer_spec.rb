# frozen_string_literal: true

require "rails_helper"
require "composites/home24/interactors/save_conditions_for_customer"
require "composites/home24/entities/customer"
require "composites/home24/repositories/customer_repository"

RSpec.describe Home24::Interactors::SaveConditionsForCustomer, :integration do
  subject { described_class.new(customer_repo: customer_repo) }

  let(:home24_customer) do
    instance_double(
      Home24::Entities::Customer,
      id: 1,
      home24_source: true,
      home24_data: {}
    )
  end

  let(:customer_repo) do
    instance_double(
      Home24::Repositories::CustomerRepository,
      find: home24_customer,
      save_condition_values: home24_customer
    )
  end

  let(:contract_details_condition) { true }
  let(:consultation_waiving_condition) { true }

  context "when the home24 customer exists" do
    it "calls the save_condition_values method in customer repo" do
      expect(customer_repo)
        .to receive(:save_condition_values)
        .with(home24_customer.id, contract_details_condition, consultation_waiving_condition)
      subject.call(home24_customer.id, contract_details_condition, consultation_waiving_condition)
    end

    it "is successful" do
      result = subject.call(home24_customer.id, contract_details_condition, consultation_waiving_condition)
      expect(result).to be_successful
    end

    it "exposes customer" do
      result = subject.call(home24_customer.id, contract_details_condition, consultation_waiving_condition)
      expect(result.customer.id).to eq(home24_customer.id)
    end
  end

  context "when no customer exists with that id" do
    before do
      allow(customer_repo).to receive(:find).with(home24_customer.id).and_return(nil)
    end

    it "does not initiate save of conditions  on customer repository" do
      expect(customer_repo).not_to receive(:save_condition_values)
      subject.call(home24_customer.id, contract_details_condition, consultation_waiving_condition)
    end

    it "is not successful" do
      result = subject.call(home24_customer.id, contract_details_condition, consultation_waiving_condition)
      expect(result).not_to be_successful
    end

    it "includes the customer not found error message" do
      result = subject.call(home24_customer.id, contract_details_condition, consultation_waiving_condition)
      expect(result.errors).to include I18n.t("account.wizards.home24.errors.customer_not_found")
    end
  end

  context "when customer does not have home24 source" do
    let(:customer) do
      instance_double(
        Home24::Entities::Customer,
        id: 2,
        home24_source: false
      )
    end

    before do
      allow(customer_repo).to receive(:find).with(customer.id).and_return(customer)
    end

    it "does not call save_condition_values on customer repository" do
      expect(customer_repo).not_to receive(:save_condition_values)
      subject.call(customer.id, contract_details_condition, consultation_waiving_condition)
    end

    it "is not successful" do
      result = subject.call(customer.id, contract_details_condition, consultation_waiving_condition)
      expect(result).not_to be_successful
    end

    it "includes error message" do
      result = subject.call(customer.id, contract_details_condition, consultation_waiving_condition)
      expect(result.errors).to include I18n.t("account.wizards.home24.errors.not_allowed")
    end
  end
end
