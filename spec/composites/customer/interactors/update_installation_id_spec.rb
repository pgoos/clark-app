# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/update_installation_id"

RSpec.describe Customer::Interactors::UpdateInstallationId do
  subject { described_class.new(repo: customer_repo) }

  let(:ip) { Faker::Internet.ip_v4_address }
  let(:installation_id) { Faker::Internet.device_token }
  let(:customer_repo) { double :customer_repo, find: customer, installation_id_exists?: false, update!: true }
  let(:customer) { double :customer, id: 999, installation_id: nil }
  let(:updated_customer) { double :updated_customer }

  context "with valid installation_id" do
    context "customer has no previous installation_id" do
      it "updates customer and returns updated customer" do
        expect(customer_repo).to receive(:find).and_return(customer, updated_customer)
        result = subject.call(customer.id, installation_id)
        expect(result).to be_successful
        expect(result.customer).to eq(updated_customer)
      end
    end

    context "customer has the same installation_id " do
      before { allow(customer).to receive(:installation_id).and_return(installation_id) }

      it "returns the customer without any update" do
        expect(customer_repo).to receive(:find).and_return(customer)
        result = subject.call(customer.id, installation_id)
        expect(result).to be_successful
        expect(result.customer).to eq(customer)
      end
    end
  end

  context "with invalid installation_id" do
    context "installation_id already exists" do
      before { allow(customer_repo).to receive(:installation_id_exists?).and_return(true) }

      it "returns error result" do
        result = subject.call(customer.id, installation_id)
        expect(result).to be_failure
        expect(result.errors).not_to be_empty
      end
    end

    context "customer has different installation_id" do
      before { allow(customer).to receive(:installation_id).and_return("something") }

      it "returns error result" do
        result = subject.call(customer.id, installation_id)
        expect(result).to be_failure
        expect(result.errors).not_to be_empty
      end
    end
  end
end
