# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/customer_repository"

RSpec.describe Salesforce::Repositories::CustomerRepository do
  subject(:repository) { described_class.new }

  let(:mandate) { create(:mandate) }

  describe "#find" do
    it "returns customer" do
      customer = repository.find(mandate.id)
      expect(customer).to be_kind_of Mandate
      expect(customer.id).to eq(mandate.id)
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repository.find(9999)).to be_nil
      end
    end
  end
end
