# frozen_string_literal: true

require "rails_helper"
require "composites/carrier"

RSpec.describe Carrier::Constituents::Arisecur::Interactors::TransferSignedMandate, :integration do
  subject { described_class.new(carrier_data_repo: carrier_data_repo, customer_repo: customer_repo) }

  let(:carrier_data_repo) { instance_double(Carrier::Repositories::CarrierDataRepository) }
  let(:customer_repo) { instance_double(Carrier::Repositories::CustomerRepository) }

  context "when contract does not exist" do
    before { allow(carrier_data_repo).to receive(:find_by_contract_number).and_return nil }

    it "returns error" do
      result = subject.call(1)
      expect(result).not_to be_successful
      expect(result.errors).to eq ["Contract does not exist!"]
    end
  end

  context "when contract exists" do
    let(:contract_hash) {
      {
        contract_number: "123", \
      customer_number: "123", product_id: 1
      }
    }
    let(:contract) {
      instance_double(Carrier::Entities::CarrierData, id: 1, \
        customer_id: 1, state: "product_created", to_h: contract_hash)
    }

    let(:pdf_file) do
      fixture_file_upload(Rails.root.join("spec", "fixtures", "dummy-mandate.pdf"), "application/pdf")
    end

    let(:create_request) do
      instance_double(
        Carrier::Constituents::Arisecur::Outbound::Requests::TransferSignedMandate,
        response_body: { "Id" => "1234" },
        response_successful?: true
      )
    end

    before do
      allow(pdf_file).to receive(:filename).and_return("dummy-mandate.pdf")
      allow(carrier_data_repo)
        .to receive(:find_by_contract_number)
        .and_return(contract)
      allow(customer_repo)
        .to receive(:signed_mandate)
        .and_return(pdf_file)
      allow(customer_repo)
        .to receive(:find)
        .with(contract.customer_id, include_carrier_data: true)
        .and_return(contract)
    end

    it "creates customer in Arisecur platform" do
      expect(Carrier::Constituents::Arisecur::Outbound::Requests::TransferSignedMandate)
        .to receive(:new).with(contract.to_h).and_return(create_request)
      expect(create_request).to receive(:call)
      expect(carrier_data_repo).to receive(:update_state!).with(contract.id, "document_transferred")
      result = subject.call(contract.id)
      expect(result).to be_successful
    end
  end
end
