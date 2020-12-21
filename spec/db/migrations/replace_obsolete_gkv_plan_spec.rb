# frozen_string_literal: true

require "rails_helper"

require "migration_data/testing"
require_migration "replace_obsolete_gkv_plan"

RSpec.describe ReplaceObsoleteGkvPlan, :integration do
  describe "#data" do
    let!(:obsolete_plan) { create(:plan, ident: described_class::OBSOLETE_PLAN_IDENT) }
    let!(:real_plan) { create(:plan, ident: described_class::REAL_PLAN_IDENT) }

    let!(:products) { create_list(:product, 2, plan: obsolete_plan) }
    let!(:other_products) { create_list(:product, 2, plan: real_plan) }

    it "replaces products with obsolete plans" do
      described_class.new.data

      all_products = Product.where(plan: real_plan)
      expect(all_products.size).to eq 4

      products.each(&:reload)
      expect(products.first.plan).to eq real_plan
      expect(products.second.plan).to eq real_plan

      expect(obsolete_plan.reload).to be_inactive
    end
  end
end
