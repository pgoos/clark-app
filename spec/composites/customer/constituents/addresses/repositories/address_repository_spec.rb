# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/addresses/repositories/address_repository"

RSpec.describe Customer::Constituents::Addresses::Repositories::AddressRepository, :integration do
  subject(:repo) { described_class.new }

  let(:mandate) { create(:mandate, :freebie) }
  let(:address) { mandate.active_address }

  describe "#find_attributes_by" do
    it "returns entity with aggregated data" do
      addr = repo.find_attributes_by(customer_id: mandate.id)

      expect(addr).to be_kind_of Hash
      expect(addr[:id]).to eq address.id
      expect(addr[:customer_id]).to eq mandate.id
      expect(addr[:street]).to eq address.street
      expect(addr[:house_number]).to eq address.house_number
      expect(addr[:zipcode]).to eq address.zipcode
      expect(addr[:city]).to eq address.city
    end

    context "when address does not exist" do
      it "returns nil" do
        expect(repo.find_attributes_by(customer_id: 999)).to be_nil
      end
    end
  end

  describe "#update!" do
    let(:new_street) { "Vuter Goli" }
    let(:new_house_number) { "9" }
    let(:new_city) { "Frankfurt" }
    let(:new_zipcode) { "63065" }

    let(:address_attributes) do
      {
        street: new_street,
        house_number: new_house_number,
        city: new_city,
        zipcode: new_zipcode
      }
    end

    context "fails on validation" do
      let(:new_street) { nil } # Freebie mandate requires address fields

      it do
        expect { repo.update!(mandate.id, address_attributes) }
          .to raise_error(Utils::Repository::Errors::ValidationError)
      end
    end

    context "updates address for customer" do
      it do
        repo.update!(mandate.id, address_attributes)
        mandate.reload
        address = mandate.active_address

        expect(address.street).to eq new_street
        expect(address.house_number).to eq new_house_number
        expect(address.city).to eq new_city
        expect(address.zipcode).to eq new_zipcode
      end
    end
  end
end
