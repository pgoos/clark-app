# frozen_string_literal: true

require "rails_helper"
require "composites/carrier"

RSpec.describe Carrier::Constituents::Arisecur::Interactors::StockTransfer, :integration do
  subject do
    described_class.new(product_repo: product_repo, carrier_data_repo: carrier_data_repo, state_machine: state_machine)
  end

  let(:carrier_data_repo) { instance_double(Carrier::Repositories::CarrierDataRepository) }
  let(:product_repo) { instance_double(Carrier::Repositories::ProductRepository) }
  let(:state_machine) { double(Carrier::Constituents::Arisecur::StateMachines::CarrierDataStateMachine) }

  context "when product does not exist" do
    before { allow(product_repo).to receive(:find).and_return nil }

    it "returns error" do
      result = subject.call(1)
      expect(result).not_to be_successful
      expect(result.product).to be_nil
      expect(result.errors).to eq ["Product does not exist!"]
    end
  end

  context "when product exists" do
    let(:product) do
      instance_double(Carrier::Entities::Product, id: 1, customer_id: 1)
    end
    let(:carrier_data) do
      instance_double(
        Carrier::Entities::CarrierData, id: 1, state: "product_takeoveer_requested", contract_number: "1234"
      )
    end
    let(:result) do
      instance_double(Utils::Interactor::Result, success?: true)
    end
    let(:create_customer) do
      instance_double(Carrier::Constituents::Arisecur::Interactors::CreateCustomer, call: result)
    end
    let(:create_product) do
      instance_double(Carrier::Constituents::Arisecur::Interactors::CreateProduct, call: result)
    end
    let(:transfer_signed_mandate) do
      instance_double(Carrier::Constituents::Arisecur::Interactors::TransferSignedMandate, call: result)
    end
    let(:product_request_takeover) do
      instance_double(Carrier::Constituents::Arisecur::Interactors::ProductRequestTakeover, call: result)
    end

    before do
      allow(product_repo).to receive(:find).with(product.id).and_return(product)
      allow(carrier_data_repo).to receive(:find_by_product).with(product.id).and_return(carrier_data)
      allow(state_machine).to receive(:fire_event!).and_return("completed")
    end

    it "runs all the steps of BU process" do
      expect(Carrier::Constituents::Arisecur::Interactors::CreateCustomer)
        .to receive(:new)
        .and_return(create_customer)
      expect(Carrier::Constituents::Arisecur::Interactors::CreateProduct)
        .to receive(:new)
        .and_return(create_product)
      expect(Carrier::Constituents::Arisecur::Interactors::TransferSignedMandate)
        .to receive(:new)
        .and_return(transfer_signed_mandate)
      expect(Carrier::Constituents::Arisecur::Interactors::ProductRequestTakeover)
        .to receive(:new)
        .and_return(product_request_takeover)
      expect(carrier_data_repo)
        .to receive(:update_state!)
        .with(carrier_data.id, "completed")
        .and_return(carrier_data)
      subject.call(product.id)
    end
  end
end
