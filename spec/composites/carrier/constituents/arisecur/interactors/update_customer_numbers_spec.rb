# frozen_string_literal: true

require "rails_helper"
require "composites/carrier"

RSpec.describe Carrier::Constituents::Arisecur::Interactors::UpdateCustomerNumbers, :integration do
  subject { described_class.new(customer_repo: customer_repo, carrier_data_repo: carrier_data_repo) }

  let(:carrier_data_repo) { instance_double(Carrier::Repositories::CarrierDataRepository) }
  let(:customer_repo) { instance_double(Carrier::Repositories::CustomerRepository) }
  let(:customer_number) { "1234" }

  context "when customer does not exist" do
    before { allow(customer_repo).to receive(:find).and_return nil }

    it "returns error" do
      result = subject.call(1, customer_number)
      expect(result).not_to be_successful
      expect(result.errors).to eq ["Customer does not exist!"]
    end
  end

  context "when customer exists" do
    let(:customer) do
      instance_double(
        Carrier::Entities::Customer, id: 1
      )
    end

    before do
      allow(customer_repo).to receive(:find).and_return(customer)
    end

    context "and carrier data exist" do
      before do
        allow(carrier_data_repo)
          .to receive(:update_all_customer_numbers!)
          .with(customer.id, customer_number)
          .and_return true
      end

      it "updates customer number" do
        result = subject.call(customer.id, customer_number)
        expect(result).to be_successful
      end
    end

    context "and carrier data don't exist" do
      before do
        allow(carrier_data_repo)
          .to receive(:update_all_customer_numbers!)
          .with(customer.id, customer_number)
          .and_return false
      end

      it "returns error" do
        result = subject.call(customer.id, customer_number)
        expect(result).not_to be_successful
        expect(result.errors).to eq ["Unable to update customer numbers!"]
      end
    end
  end
end
