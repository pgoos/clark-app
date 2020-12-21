# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/repositories/carrier_data_repository"

RSpec.describe Carrier::Repositories::CarrierDataRepository, :integration do
  subject(:repository) { described_class.new }

  let(:mandate) { create(:mandate) }
  let(:product) { create(:product) }
  let!(:carrier_data) { create(:carrier_data, mandate: mandate, product: product) }

  describe "#find_by_customer" do
    it "returns aggregated entity with aggregated data" do
      result = repository.find_by_customer(mandate.id)

      expect(result).to be_kind_of Carrier::Entities::CarrierData
      expect(result.id).to eq(carrier_data.id)
    end

    context "when carrier_data does not exist" do
      it "returns nil" do
        expect(repository.find_by_customer(9999)).to be_nil
      end
    end
  end

  describe "#find_by_product" do
    it "returns aggregated entity with aggregated data" do
      result = repository.find_by_product(product.id)

      expect(result).to be_kind_of Carrier::Entities::CarrierData
      expect(result.id).to eq(carrier_data.id)
    end

    context "when carrier_data does not exist" do
      it "returns nil" do
        expect(repository.find_by_product(9999)).to be_nil
      end
    end
  end

  describe "#create_by_customer!" do
    it "creates a new carrier_data record" do
      result = repository.create_by_customer!(mandate.id)
      expect(result).to be_kind_of Carrier::Entities::CarrierData
      expect { repository.create_by_customer!(mandate.id) }.to change(CarrierData, :count).by(1)
      expect(carrier_data.reload.mandate_id).to eq(mandate.id)
    end
  end

  describe "#update_all_customer_numbers!" do
    it "updates customer number for selected carrier data" do
      result = repository.update_all_customer_numbers!(mandate.id, "10")
      expect(result).to eq(true)
    end
  end

  describe "#update_customer_number!" do
    it "updates customer number for selected carrier data" do
      result = repository.update_customer_number!(mandate.id, "10")
      expect(result).to be_kind_of Carrier::Entities::CarrierData
      expect(result.id).to eq(carrier_data.id)
      expect(carrier_data.reload.customer_number).to eq("10")
    end
  end

  describe "#assign_product!" do
    let!(:product2) { create(:product) }

    context "when carrier_data exists" do
      let!(:carrier_data) { create(:carrier_data, mandate_id: mandate.id, product_id: nil) }

      it "updates customer number for selected carrier data" do
        result = repository.assign_product!(mandate.id, product2.id)
        expect(result).to be_kind_of Carrier::Entities::CarrierData
        expect(result.id).to eq(carrier_data.id)
        expect(carrier_data.reload.product_id).to eq(product2.id)
      end
    end

    context "when carrier_data does not exist" do
      it "creates carrier_data record" do
        expect { repository.assign_product!(mandate.id, product2.id) }.to change(CarrierData, :count).by(1)
      end
    end
  end

  describe "#update_contract_number!" do
    it "updates contract number for selected carrier data" do
      result = repository.update_contract_number!(product.id, "100")
      expect(result).to be_kind_of Carrier::Entities::CarrierData
      expect(result.id).to eq(carrier_data.id)
      expect(carrier_data.reload.contract_number).to eq("100")
    end
  end

  describe "#update_state!" do
    it "updates state for selected carrier_data" do
      result = repository.update_state!(carrier_data.id, "product_created")
      expect(result).to be_kind_of Carrier::Entities::CarrierData
      expect(result.id).to eq(carrier_data.id)
      expect(carrier_data.reload.state).to eq("product_created")
    end
  end
end
