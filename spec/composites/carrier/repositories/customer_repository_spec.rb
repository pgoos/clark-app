# frozen_string_literal: true

require "rails_helper"
require "composites/carrier"

RSpec.describe Carrier::Repositories::CustomerRepository, :integration do
  subject(:repository) { described_class.new }

  let(:mandate) { create(:mandate) }
  let!(:user) { create(:user, mandate: mandate) }

  describe "#find" do
    it "returns aggregated entity with aggregated data" do
      customer = repository.find(mandate.id)

      expect(customer).to be_kind_of Carrier::Entities::Customer
      expect(customer.id).to eq(mandate.id)
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repository.find(9999)).to be_nil
      end
    end
  end
end
