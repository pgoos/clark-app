# frozen_string_literal: true

require "rails_helper"
require "composites/carrier"

RSpec.describe Carrier::Constituents::Arisecur::Interactors::ProductRequestTakeover, :integration do
  subject do
    described_class.new(
      product_repo: product_repo,
      carrier_data_repo: carrier_data_repo
    )
  end

  let(:product_repo) { instance_double(Carrier::Repositories::ProductRepository) }
  let(:carrier_data_repo) { instance_double(Carrier::Repositories::CarrierDataRepository) }

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
    let(:carrier_data) { instance_double(Carrier::Entities::CarrierData, id: 1, customer_id: 1) }
    let(:product) { instance_double(Carrier::Entities::Product, id: 1, customer_id: 1) }

    before do
      allow(product_repo).to receive(:find).and_return(product)
      allow(carrier_data_repo).to receive(:find_by_product).with(product.id).and_return(carrier_data)
    end

    context "when product is in details_available state" do
      before do
        allow(product).to receive_messages(state: "details_available", takeover_requested?: false)
      end

      context "when attached carrier_data is in document_transferred state" do
        before do
          allow(carrier_data).to receive(:state).and_return("document_transferred")
        end

        it "returns product and update both states" do
          expect(product_repo)
            .to receive(:update_state!)
            .with(carrier_data.id, "takeover_requested")
            .and_return(carrier_data)
          expect(carrier_data_repo)
            .to receive(:update_state!)
            .with(carrier_data.id, "product_takeover_requested")
            .and_return(carrier_data)
          result = subject.call(1)
          expect(result).to be_successful
          expect(result.product.id).to eq product.id
        end
      end
    end

    context "when product is already in takeover_requested state" do
      before do
        allow(product).to receive_messages(state: "takeover_requested", takeover_requested?: true)
        allow(carrier_data).to receive(:state).and_return("document_transferred")
      end

      it "returns product and update carrier_data state" do
        expect(carrier_data_repo)
          .to receive(:update_state!)
          .with(carrier_data.id, "product_takeover_requested")
        result = subject.call(1)
        expect(result).to be_successful
        expect(result.product.id).to eq product.id
      end
    end
  end
end
