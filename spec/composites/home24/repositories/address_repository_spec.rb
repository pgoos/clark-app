# frozen_string_literal: true

require "rails_helper"
require "composites/home24/repositories/address_repository"

RSpec.describe Home24::Repositories::AddressRepository, :integration do
  subject(:repo) { described_class.new }

  let(:mandate) { create(:mandate, :home24) }
  let(:address) { mandate.active_address }

  describe "#find_by" do
    it "returns entity with aggregated data" do
      addr = repo.find_by(customer_id: mandate.id)

      expect(addr).to be_kind_of Home24::Entities::Address
      expect(addr.id).to eq address.id
      expect(addr.customer_id).to eq mandate.id
      expect(addr.street).to eq address.street
      expect(addr.house_number).to eq address.house_number
      expect(addr.zipcode).to eq address.zipcode
      expect(addr.city).to eq address.city
    end

    context "when there is no address associated with customer_id" do
      it "returns nil" do
        expect(repo.find_by(customer_id: 999)).to be_nil
      end
    end
  end
end
