# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "add_standard_new_contract_channels_to_subcompanies"

describe AddStandardNewContractChannelsToSubcompanies do
  describe "#data" do
    context "when makler pools is 'fonds_finanz'" do
      let!(:subcompany) { create :subcompany, pools: [Subcompany::POOL_FONDS_FINANZ] }

      it "sets fields to fonds_finanz" do
        described_class.new.data
        subcompany.reload
        expect(subcompany).to be_standard_new_contract_sales_channel_fonds_finanz
        expect(subcompany).to be_standard_new_contract_management_channel_fonds_finanz
      end
    end

    context "when makler pools is 'quality_pool'" do
      let!(:subcompany) { create :subcompany, pools: [Subcompany::POOL_QUALITY_POOL] }

      it "sets fields to quality_pool" do
        described_class.new.data
        subcompany.reload
        expect(subcompany).to be_standard_new_contract_sales_channel_quality_pool
        expect(subcompany).to be_standard_new_contract_management_channel_quality_pool
      end
    end

    context "when makler pools is 'direct_agreement'" do
      let!(:subcompany) { create :subcompany, pools: [Subcompany::POOL_DIRECT_AGREEMENT] }

      it "sets fields to direct_agreement" do
        described_class.new.data
        subcompany.reload
        expect(subcompany).to be_standard_new_contract_sales_channel_direct_agreement
        expect(subcompany).to be_standard_new_contract_management_channel_direct_agreement
      end
    end

    context "when makler pools is empty" do
      let!(:subcompany) { create :subcompany, pools: [] }

      it "sets fields to undefined" do
        described_class.new.data
        subcompany.reload
        expect(subcompany).to be_standard_new_contract_sales_channel_undefined
        expect(subcompany).to be_standard_new_contract_management_channel_undefined
      end
    end

    context "when makler pools is 'fonds_finanz' and 'quality_pool'" do
      let!(:subcompany) { create :subcompany, pools: [Subcompany::POOL_FONDS_FINANZ, Subcompany::POOL_QUALITY_POOL] }

      it "sets fields to quality_pool" do
        described_class.new.data
        subcompany.reload
        expect(subcompany).to be_standard_new_contract_sales_channel_quality_pool
        expect(subcompany).to be_standard_new_contract_management_channel_quality_pool
      end
    end
  end
end
