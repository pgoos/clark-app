# frozen_string_literal: true

require "rails_helper"
require "composites/carrier"

RSpec.describe Carrier::Constituents::Arisecur::Interactors::CreateProduct, :integration do
  subject { described_class.new(product_repo: product_repo, carrier_data_repo: carrier_data_repo) }

  let(:carrier_data_repo) { instance_double(Carrier::Repositories::CarrierDataRepository) }
  let(:product_repo) { instance_double(Carrier::Repositories::ProductRepository) }

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
    let(:product_hash) {
      {
        id: 1,
        product_number: "AOEI",
        premium_price: 10_000,
        beggining_of_contract: DateTime.now - 2.years,
        end_of_contract: DateTime.now + 1.year
      }
    }
    let(:carrier_data) {
      instance_double(Carrier::Entities::CarrierData, id: 1, customer_id: 1, contract_number: "", \
                            state: "customer_created", customer_number: "123", product_id: nil)
    }
    let(:product) do
      instance_double(
        Carrier::Entities::Product, id: 1, customer_id: 1, to_h: product_hash
      )
    end
    let(:create_request) do
      instance_double(
        Carrier::Constituents::Arisecur::Outbound::Requests::CreateProduct,
        response_body: { "Id" => "1234" },
        response_successful?: true
      )
    end

    before do
      allow(product_repo).to receive(:find).and_return(product)
      allow(carrier_data_repo).to receive(:find_by_product).and_return(nil)
      allow(carrier_data_repo).to receive(:find_by_customer).and_return(carrier_data)
    end

    it "creates product in Arisecur platform" do
      expect(Carrier::Constituents::Arisecur::Outbound::Requests::CreateProduct)
        .to receive(:new).with(product.to_h).and_return(create_request)
      expect(create_request).to receive(:call)
      expect(carrier_data_repo)
        .to receive(:assign_product!)
        .with(product.customer_id, product.id)
        .and_return(carrier_data)
      expect(carrier_data_repo).to receive(:update_contract_number!).with(product.id, "1234")
      expect(carrier_data_repo).to receive(:update_state!).with(carrier_data.id, "product_created")
      result = subject.call(product.id)
      expect(result).to be_successful
    end
  end
end
