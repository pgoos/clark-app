# frozen_string_literal: true

require "rails_helper"
require "composites/home24/repositories/product_repository"

RSpec.describe Home24::Repositories::ProductRepository, :integration do
  subject(:repo) { described_class.new }

  let(:mandate) { create(:mandate, :home24) }
  let(:product) { create(:product, mandate: mandate) }

  describe "#find" do
    it "returns entity with aggregated data" do
      product_entity = repo.find(product.id)

      expect(product_entity).to be_kind_of Home24::Entities::Product
      expect(product_entity.id).to eq product.id
      expect(product_entity.customer_id).to eq product.mandate_id
      expect(product_entity.plan_id).to eq product.plan_id
      expect(product_entity.state).to eq product.state
      expect(product_entity.contract_started_at).to eq product.contract_started_at
      expect(product_entity.contract_ended_at).to eq product.contract_ended_at
    end

    context "when products doesn't exist" do
      it "returns nil" do
        expect(repo.find(99)).to be_nil
      end
    end
  end
end
