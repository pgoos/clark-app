# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Constituents::UpgradeJourney::Interactors::Start do
  subject(:start) { described_class.new(customer_repo: customer_repo) }

  let(:customer_id) { 999 }
  let(:customer_repo) { double :repo, find: customer, update!: true }
  let(:updated_customer) { double :customer }
  let(:customer_state) { "prospect" }
  let(:mandate_state) { "not_started" }

  let(:customer) do
    double(
      :customer,
      id: customer_id,
      mandate_state: mandate_state,
      customer_state: customer_state
    )
  end

  let(:attributes) do
    {
      mandate_state: "in_creation"
    }
  end

  context "new customer" do
    it "updates customer states and attributes" do
      expect(customer_repo).to receive(:update!).with(customer_id, attributes)
      expect(customer_repo).to receive(:find).twice.and_return(customer, updated_customer)

      result = start.(customer_id)

      expect(result).to be_successful
      expect(result.customer).to eq updated_customer
      expect(result.modified).to eq true
    end
  end

  context "already stated customer" do
    let(:mandate_state) { "in_creation" }

    it "returns the customer without changes" do
      expect(customer_repo).not_to receive(:update!)
      expect(customer_repo).to receive(:find).once.and_return(customer)

      result = start.(customer_id)

      expect(result).to be_successful
      expect(result.customer).to eq customer
      expect(result.modified).to eq false
    end
  end

  context "when customer does not exist" do
    let(:customer_repo) { double :repo, find: nil }

    it "returns failure" do
      result = start.(customer_id)
      expect(result).to be_failure
    end
  end
end
