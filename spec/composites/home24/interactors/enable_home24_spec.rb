# frozen_string_literal: true

require "rails_helper"
require "composites/home24/interactors/enable_home24"
require "composites/home24/entities/customer"
require "composites/home24/repositories/customer_repository"

RSpec.describe Home24::Interactors::EnableHome24, :integration do
  subject { described_class.new(customer_repo: customer_repo, save_home24_order_number: save_home24_order_number) }

  include_context "home24 with order"

  let(:order_number) { home24_order_number }

  let(:customer) do
    instance_double(
      Home24::Entities::Customer,
      id: 1,
      mandate_state: "in_creation",
      home24_source: false
    )
  end

  let(:home24_enabled_customer) do
    instance_double(
      Home24::Entities::Customer,
      id: 1,
      home24_source: true
    )
  end

  let(:customer_repo) do
    instance_double(
      Home24::Repositories::CustomerRepository,
      find: customer,
      enable_home24: home24_enabled_customer,
    )
  end

  let(:save_home24_order_number) { double(call: double(customer: home24_enabled_customer)) }

  it "calls the enable_home24 method in customer repository" do
    expect(customer_repo).to receive(:enable_home24).with(1)
    subject.call(customer.id)
  end

  it "is successful" do
    result = subject.call(customer.id)
    expect(result).to be_successful
  end

  it "sets the home24_source to true" do
    result = subject.call(customer.id)
    expect(result.customer.home24_source).to be_truthy
  end

  context "when there is passed the utm_order_no" do
    let(:utm_order_no) { order_number }

    it "calls the enable_home24 method in customer repository" do
      expect(customer_repo).to receive(:enable_home24).with(customer.id)
      subject.call(customer.id, utm_order_no)
    end

    it "is successful" do
      result = subject.call(customer.id, utm_order_no)
      expect(result).to be_successful
    end

    it "saves the order number" do
      expect(save_home24_order_number).to receive(:call).with(customer.id, utm_order_no)
      subject.call(customer.id, utm_order_no)
    end
  end

  context "when the customer does not exist" do
    before do
      allow(customer_repo).to receive(:find).with(customer.id).and_return(nil)
    end

    it "does not call enable_home24 on customer repository" do
      expect(customer_repo).not_to receive(:enable_home24)
      subject.call(customer.id)
    end

    it "is not successful" do
      result = subject.call(customer.id)
      expect(result).not_to be_successful
    end

    it "includes the customer not found error message" do
      result = subject.call(customer.id)
      expect(result.errors).to include I18n.t("account.wizards.home24.errors.customer_not_found")
    end
  end

  context "when the customer mandate state is not `in_creation` or `not_started`" do
    let(:accepted_customer) do
      instance_double(
        Home24::Entities::Customer,
        id: 2,
        mandate_state: "accepted",
        home24_source: false
      )
    end

    before do
      allow(customer_repo).to receive(:find).with(accepted_customer.id).and_return(accepted_customer)
    end

    it "does not call enable_home24 on customer repository" do
      expect(customer_repo).not_to receive(:enable_home24)
      subject.call(accepted_customer.id)
    end

    it "is not successful" do
      result = subject.call(accepted_customer.id)
      expect(result).not_to be_successful
    end

    it "includes the error message" do
      result = subject.call(accepted_customer.id)
      expect(result.errors).to include I18n.t("account.wizards.home24.errors.not_allowed")
    end
  end
end
