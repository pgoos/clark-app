# frozen_string_literal: true

require "rails_helper"
require "composites/home24/interactors/find_customer"
require "composites/home24/repositories/customer_repository"

RSpec.describe Home24::Interactors::FindCustomer, :integration do
  subject { described_class.new(customer_repo: customer_repo) }

  let(:customer) { instance_double(Home24::Entities::Customer, id: 1, home24_source: false) }

  let(:customer_repo) do
    instance_double(
      Home24::Repositories::CustomerRepository,
      find: customer
    )
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

    it "expects the id of custmer returned to be same with the one mocked" do
      result = subject.call(customer.id)
      expect(result.customer).to eq customer
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
  end
end
