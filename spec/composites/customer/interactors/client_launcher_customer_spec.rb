# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/client_launcher_customer"

RSpec.describe Customer::Interactors::ClientLauncherCustomer do
  subject { described_class.new(customers: customer_repo, accounts: account_repo) }

  let(:customer_repo) { double(:repo, find: nil, find_by_installation_id: nil) }
  let(:account_repo) { double(:repo, find_by_credentials: nil) }

  let(:account) { double(:account, customer_id: 999) }
  let(:customer) { double(:customer, registered: false) }

  before do
    allow(account_repo).to receive(:find_by_credentials).with("email", "password").and_return account
    allow(customer_repo).to receive(:find_by_installation_id).with("IID").and_return customer
    allow(customer_repo).to receive(:find).with(999).and_return customer
  end

  context "with user credentials" do
    context "when customer is not found" do
      it "tries to find customer by installation id" do
        expect(customer_repo).to receive(:find_by_installation_id).with("IID").and_return customer
        result = subject.({ email: "FOO", password: "BAR" }, "IID")
        expect(result.customer).to eq customer
      end
    end

    context "when customer is found" do
      it "returns customer" do
        result = subject.({ email: "email", password: "password" }, nil)
        expect(result.customer).to eq customer
      end
    end
  end

  context "with installation id" do
    context "when customer is not found" do
      it "returns nil" do
        result = subject.({}, "FOO")
        expect(result).to be_successful
        expect(result.customer).to eq nil
        expect(result.installation_id_already_registered).to eq nil
      end
    end

    context "when customer is found" do
      it "returns customer" do
        result = subject.({}, "IID")
        expect(result).to be_successful
        expect(result.customer).to eq customer
        expect(result.installation_id_already_registered).to eq false
      end

      context "when customer is registered" do
        let(:customer) { double(:customer, registered: true) }

        it "returns nil" do
          result = subject.({}, "IID")
          expect(result).to be_successful
          expect(result.customer).to be_nil
          expect(result.installation_id_already_registered).to eq true
        end
      end
    end
  end
end
