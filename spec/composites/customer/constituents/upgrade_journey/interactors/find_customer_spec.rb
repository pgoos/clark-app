# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/upgrade_journey/interactors/find_customer"

RSpec.describe Customer::Constituents::UpgradeJourney::Interactors::FindCustomer do
  subject { described_class.new(customer_repo: customer_repo) }

  let(:customer) { double :customer, id: 909 }

  context "when customer exists" do
    let(:customer_repo) { double :repo, find: customer }

    it "returns customer" do
      expect(customer_repo).to receive(:find).with(customer.id, include_profile: true)
      result = subject.call(customer.id)
      expect(result).to be_successful
      expect(result.customer.id).to eq(customer.id)
    end
  end

  context "when customer doesn't exist" do
    let(:customer_repo) { double :repo, find: nil }

    it "returns result with failure" do
      result = subject.call(customer.id)
      expect(result).to be_failure
    end
  end
end
