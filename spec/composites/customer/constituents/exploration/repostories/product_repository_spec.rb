# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/exploration/repositories/product_repository"

RSpec.describe Customer::Constituents::Exploration::Repositories::ProductRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#find_active_non_state_product" do
    it "returns product with aggregated data" do
      mandate = create(:mandate)
      product = create(:product, mandate: mandate, analysis_state: "details_missing")

      result = repo.find_active_non_state_product(mandate.id)
      expect(result).to be_kind_of Customer::Constituents::Exploration::Entities::Product
      expect(result.id).to eql(product.id)
    end

    context "when product does not exist" do
      it "returns nil" do
        expect(repo.find_active_non_state_product(999)).to be_nil
      end
    end
  end
end
