# frozen_string_literal: true

require "rails_helper"
require "composites/home24/interactors/save_home24_order_number_spec"
require "composites/home24/entities/customer"
require "composites/home24/repositories/customer_repository"

RSpec.describe Home24::Interactors::SaveHome24OrderNumber, :integration do
  subject { described_class.new(customer_repo: customer_repo) }

  include_context "home24 with order"

  let(:order_number) { home24_order_number }

  let(:home24_customer) do
    instance_double(
      Home24::Entities::Customer,
      id: 1,
      home24_source: true,
      home24_data: {},
      order_number: false
    )
  end

  let(:home24_customer_with_data) do
    instance_double(
      Home24::Entities::Customer,
      id: 1,
      home24_source: true,
      home24_data: { "order_number" => order_number }
    )
  end

  let(:customer_repo) do
    instance_double(
      Home24::Repositories::CustomerRepository,
      find: home24_customer,
      save_order_number: home24_customer_with_data,
      order_number_unique?: true
    )
  end

  context "when the home24 customer exists" do
    it "calls the save_order_number method in customer repo" do
      expect(customer_repo).to receive(:save_order_number).with(home24_customer.id, order_number)
      subject.call(home24_customer.id, order_number)
    end

    it "is successful" do
      result = subject.call(home24_customer.id, order_number)
      expect(result).to be_successful
    end

    it "exposes customer" do
      result = subject.call(home24_customer.id, order_number)
      expect(result.customer.id).to eq(home24_customer.id)
    end
  end

  context "when no customer exists with that id" do
    before do
      allow(customer_repo).to receive(:find).with(home24_customer.id).and_return(nil)
    end

    it "does not call enable_home24 on customer repository" do
      expect(customer_repo).not_to receive(:save_order_number)
      subject.call(home24_customer.id, order_number)
    end

    it "is not successful" do
      result = subject.call(home24_customer.id, order_number)
      expect(result).not_to be_successful
    end

    it "includes the customer not found error message" do
      result = subject.call(home24_customer.id, order_number)
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

    it "does not call enable_home24 on customer repository" do
      expect(customer_repo).not_to receive(:save_order_number)
      subject.call(customer.id, order_number)
    end

    it "is not successful" do
      result = subject.call(customer.id, order_number)
      expect(result).not_to be_successful
    end

    it "includes error message" do
      result = subject.call(customer.id, order_number)
      expect(result.errors).to include I18n.t("account.wizards.home24.errors.not_allowed")
    end
  end

  context "when the order number does not have 10 digits" do
    let(:short_order_number) { "101" }

    it "is not successful" do
      result = subject.call(home24_customer.id, short_order_number)
      expect(result).not_to be_successful
    end

    it "includes the invalid_order_number error message" do
      result = subject.call(home24_customer.id, short_order_number)
      expect(result.errors).to include I18n.t("account.wizards.home24.errors.invalid_order_number")
    end
  end

  context "when the order number has the prefix `101`" do
    it "is is successful" do
      result = subject.call(home24_customer.id, order_number)
      expect(result).to be_successful
    end
  end

  context "when the order number has the prefix `100`" do
    let(:order_number) { home24_order_number_100_prefix }

    it "is is successful" do
      result = subject.call(home24_customer.id, order_number)
      expect(result).to be_successful
    end
  end

  context "when the order number does not start with `101` or `100`" do
    let(:invalid_order_number) { "1231234567" }

    it "is not successful" do
      result = subject.call(home24_customer.id, invalid_order_number)
      expect(result).not_to be_successful
    end

    it "includes the invalid_order_number error message" do
      result = subject.call(home24_customer.id, invalid_order_number)
      expect(result.errors).to include I18n.t("account.wizards.home24.errors.invalid_order_number")
    end
  end

  context "when the order number has non-digit characters" do
    let(:order_number) { home24_order_number + " ~a" }

    it "is successful" do
      result = subject.call(home24_customer.id, order_number)
      expect(result).to be_successful
    end
  end

  context "when the order number is not unique" do
    before do
      allow(customer_repo).to receive(:order_number_unique?).with(order_number).and_return(false)
    end

    it "is not successful" do
      result = subject.call(home24_customer.id, order_number)
      expect(result).not_to be_successful
    end

    it "includes the invalid_order_number error message" do
      result = subject.call(home24_customer.id, order_number)
      expect(result.errors).to include I18n.t("account.wizards.home24.errors.order_number_taken")
    end
  end
end
