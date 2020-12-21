# frozen_string_literal: true

require "rails_helper"

require "migration_data/testing"
require_migration "fix_clark2_products_with_missed_analysis_state"

RSpec.describe FixClark2ProductsWithMissedAnalysisState, :integration do
  describe "#up" do
    let(:clark1_customer) { create(:mandate) }
    let(:clark2_prospect_customer) { create(:mandate, customer_state: "prospect") }
    let(:clark2_self_service_customer) { create(:mandate, customer_state: "self_service") }
    let(:clark2_mandate_customer) { create(:mandate, customer_state: "mandate_customer") }

    let!(:clark1_products) { create_list(:product, 5, mandate: clark1_customer) }
    let!(:clark2_product1) { create(:product, analysis_state: :details_complete, mandate: clark2_prospect_customer) }
    let!(:clark2_product2) { create(:product, analysis_state: :details_complete, mandate: clark2_self_service_customer) }
    let!(:clark2_product3) { create(:product, analysis_state: :details_complete, mandate: clark2_mandate_customer) }
    let!(:clark2_product4) { create(:product, analysis_state: :under_analysis, mandate: clark2_mandate_customer) }
    let!(:clark2_product5) { create(:product, analysis_state: :analysis_failed, mandate: clark2_mandate_customer) }

    let!(:clark2_non_offered_product_with_empty_analysis_state) do
      create(:product, analysis_state: nil, state: "details_available", mandate: clark2_mandate_customer)
    end

    let!(:clark2_product_with_empty_analysis_state) do
      create(:product, analysis_state: nil, mandate: clark2_prospect_customer)
    end

    it "updates clark2 not offered products with empty analysis_state to details_missing" do
      described_class.new.up

      expect(clark2_non_offered_product_with_empty_analysis_state.reload.analysis_state).to eq("details_missing")
    end

    it "updates clark2 offered products with empty analysis_state to details_complete" do
      clark2_product_with_empty_analysis_state.update_columns(state: "offered", analysis_state: nil)
      described_class.new.up

      expect(clark2_product_with_empty_analysis_state.reload.analysis_state).to eq("details_complete")
    end

    it "does not update clark1 products" do
      described_class.new.up

      expect(clark1_products.map { |product| product.reload.analysis_state }.uniq).to eq([nil])
    end

    it "does not update clark2 products with populated analysis_state field" do
      described_class.new.up

      expect(clark2_product1.reload.analysis_state).to eq("details_complete")
      expect(clark2_product2.reload.analysis_state).to eq("details_complete")
      expect(clark2_product3.reload.analysis_state).to eq("details_complete")
      expect(clark2_product4.reload.analysis_state).to eq("under_analysis")
      expect(clark2_product5.reload.analysis_state).to eq("analysis_failed")
    end
  end
end
