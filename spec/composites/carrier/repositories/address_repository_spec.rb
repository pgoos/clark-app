# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/repositories/address_repository"

RSpec.describe Carrier::Repositories::AddressRepository, :integration do
  subject(:repository) { described_class.new }

  let(:mandate) { create(:mandate) }

  describe "#find_by_customer" do
    it "returns aggregated entity with aggregated data" do
      result = repository.find_by_customer(mandate.id)

      expect(result).to be_kind_of Carrier::Entities::Address
      expect(result.id).to eq(mandate.address.id)
    end

    context "when address does not exist" do
      it "returns nil" do
        expect(repository.find_by_customer(9999)).to be_nil
      end
    end
  end
end
