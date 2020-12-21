# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/interactors/register"

RSpec.describe Customer::Constituents::Account::Interactors::Register do
  subject do
    described_class.new(
      emit_event: event_emitter,
      customer_repo: customer_repo,
      account_repo: account_repo
    )
  end

  let(:event_emitter) { double :emit_event, call: nil }

  let(:customer) { double(:customer, id: 1, customer_state: "prospect") }

  let(:account_repo)  { double :repo, create!: account, email_exists?: false }
  let(:customer_repo) { double :repo, find: registered_customer, update!: true }

  let(:account) { double :account }
  let(:registered_customer) { double :customer }

  it "exposes created account" do
    expect(account_repo).to receive(:create!).with(1, "example@clark.de", "Test1234")
    result = subject.call(customer, "example@clark.de", "Test1234")
    expect(result).to be_successful
    expect(result.account).to eq account
  end

  it "exposes customer" do
    expect(customer_repo).to receive(:update!).with(customer.id, customer_state: "self_service")
    result = subject.call(customer, "example@clark.de", "Test1234")
    expect(result).to be_successful
    expect(result.customer).to eq registered_customer
  end

  it "commits changes within a transaction" do
    expect(Utils::Repository).to receive(:transaction)
    subject.call(customer, "example@clark.de", "Test1234")
  end

  it "emits an event" do
    expect(event_emitter).to receive(:call).with(:self_service_customer_created, customer.id)
    subject.call(customer, "example@clark.de", "Test1234")
  end

  context "validations" do
    context "with invalid email" do
      let(:eamil) { "test.com" }

      it "returns error" do
        result = subject.call(customer, eamil, "Test1234")
        expect(result).not_to be_successful
        expect(result.errors).not_to be_empty
      end
    end

    context "when email already taken" do
      let(:eamil) { "email@taken.com" }

      before { allow(account_repo).to receive(:email_exists?).with(eamil).and_return(true) }

      it "returns error" do
        result = subject.call(customer, eamil, "Test1234")
        expect(result).not_to be_successful
        expect(result.errors).not_to be_empty
      end
    end

    context "with invalid password" do
      let(:password) { "abcd" }

      it "returns error" do
        result = subject.call(customer, "abc@test.com", password)
        expect(result).not_to be_successful
        expect(result.errors).not_to be_empty
      end
    end
  end
end
