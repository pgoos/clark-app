# frozen_string_literal: true

require "rails_helper"
require "composites/carrier"

RSpec.describe Carrier::Constituents::Arisecur::Interactors::CreateCustomer, :integration do
  subject { described_class.new(customer_repo: customer_repo, carrier_data_repo: carrier_data_repo) }

  let(:carrier_data_repo) { instance_double(Carrier::Repositories::CarrierDataRepository) }
  let(:customer_repo) { instance_double(Carrier::Repositories::CustomerRepository) }

  context "when customer does not exist" do
    before { allow(customer_repo).to receive(:find).and_return nil }

    it "returns error" do
      result = subject.call(1)
      expect(result).not_to be_successful
      expect(result.customer).to be_nil
      expect(result.errors).to eq ["Customer does not exist!"]
    end
  end

  context "when customer exists" do
    let(:customer_hash) { { id: 1, birthdate: DateTime.now - 40.years } }
    let(:address_hash) { { id: 1, city: "Test", zipcode: "1234" } }
    let(:carrier_data) do
      instance_double(Carrier::Entities::CarrierData, id: 1, customer_number: "1", state: "initial")
    end
    let(:address) do
      instance_double(Carrier::Entities::CarrierData, id: 1, to_h: address_hash)
    end
    let(:customer) do
      instance_double(
        Carrier::Entities::Customer, id: 1, email: "test@test.com", to_h: customer_hash,
        carrier_data: carrier_data, address: address
      )
    end
    let(:search_request) do
      instance_double(
        Carrier::Constituents::Arisecur::Outbound::Requests::SearchCustomer,
        call: nil,
        response_body: response_body,
        response_successful?: true
      )
    end

    before do
      allow(customer_repo).to receive(:find).and_return(customer)
      allow(Carrier::Constituents::Arisecur::Outbound::Requests::SearchCustomer)
        .to receive(:new)
        .with(customer.email)
        .and_return(search_request)
    end

    context "when customer exists in Arisecur" do
      context "when customer number match the Arisecur's one" do
        let(:carrier_data) { instance_double(Carrier::Entities::CarrierData, id: 1, customer_number: "1") }
        let(:response_body) { [{ "Id" => "1" }] }

        it "returns customer" do
          result = subject.call(customer.id)
          expect(result).to be_successful
          expect(result.customer.id).to eq customer.id
        end
      end

      context "when customer does not have customer_number" do
        let(:carrier_data) do
          instance_double(Carrier::Entities::CarrierData, id: 1, customer_number: "", state: "initial")
        end
        let(:response_body) { [{ "Id" => "1" }] }

        it "updates customer number" do
          expect(carrier_data_repo).to receive(:update_customer_number!).with(customer.id, "1")
          expect(carrier_data_repo).to receive(:update_state!).with(carrier_data.id, "customer_created")
          result = subject.call(customer.id)
          expect(result).to be_successful
          expect(result.customer.id).to eq customer.id
        end
      end

      context "when customer's customer_number doesnt match Arisecur one" do
        let(:carrier_data) do
          instance_double(Carrier::Entities::CarrierData, id: 1, customer_number: "1", state: "initial")
        end
        let(:response_body) { [{ "Id" => "2" }] }

        it "updates customer number" do
          expect(carrier_data_repo).to receive(:update_customer_number!).with(customer.id, "2")
          expect(carrier_data_repo).to receive(:update_state!).with(carrier_data.id, "customer_created")
          result = subject.call(customer.id)
          expect(result).to be_successful
          expect(result.customer.id).to eq customer.id
        end
      end
    end

    context "when customer does not exist in Arisecur" do
      let(:response_body) { [] }
      let(:create_request) do
        instance_double(
          Carrier::Constituents::Arisecur::Outbound::Requests::CreateCustomer,
          response_body: { "Id" => "1234" },
          response_successful?: true
        )
      end
      let(:set_address_request) do
        instance_double(
          Carrier::Constituents::Arisecur::Outbound::Requests::SetCustomerAddress,
          response_body: { "Id" => "1234" },
          response_successful?: true
        )
      end

      it "creates customer in Arisecur platform" do
        expect(Carrier::Constituents::Arisecur::Outbound::Requests::CreateCustomer)
          .to receive(:new).with(customer.to_h).and_return(create_request)
        expect(Carrier::Constituents::Arisecur::Outbound::Requests::SetCustomerAddress)
          .to receive(:new).with(address.to_h.merge(customer_number: "1234")).and_return(set_address_request)
        expect(create_request).to receive(:call)
        expect(set_address_request).to receive(:call)
        expect(carrier_data_repo).to receive(:update_customer_number!).with(customer.id, "1234")
        expect(carrier_data_repo).to receive(:update_state!).with(carrier_data.id, "customer_created")
        result = subject.call(customer.id)
        expect(result).to be_successful
        expect(result.customer.id).to eq customer.id
      end
    end
  end
end
