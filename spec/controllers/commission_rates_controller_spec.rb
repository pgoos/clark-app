# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CommissionRatesController, :integration, type: :request do
  before do
    sign_in create(:admin, role: create(:role, permissions: Permission.where(controller: "admin/commission_rates")))
  end

  describe "#retrieve_fee" do

    shared_examples "returns a json with commission data" do
      it do
        get retrieve_fee_admin_commission_rates_url(attrs.merge(locale: I18n.locale))

        expected_json = {
          rate: "1.84",
          deduction_reserve_sales: "10.0",
          deduction_fidelity_sales: "0.0"
        }.to_json

        expect(response.body).to eq(expected_json)
      end
    end

    context "when retrieves a commission based on pool" do
      let(:commission_rate) do
        create(
          :commission_rate,
          :with_subcompany,
          :with_category,
          rate: 1.84,
          deduction_reserve_sales: 10.0,
          deduction_fidelity_sales: 0.0,
        )
      end

      let(:attrs) do
        commission_rate.attributes.slice("subcompany_id", "category_id", "pool")
      end

      it_behaves_like "returns a json with commission data"
    end

    context "when retrieves a commission based on sales channel" do
      let(:commission_rate) do
        create(
          :commission_rate,
          :with_subcompany,
          :with_category,
          rate: 1.84,
          new_contract_sales_channel: "fonds_finanz",
          deduction_reserve_sales: 10.0,
          deduction_fidelity_sales: 0.0,
        )
      end

      let(:attrs) do
        commission_rate.attributes.slice("subcompany_id", "category_id", "new_contract_sales_channel")
      end

      it_behaves_like "returns a json with commission data"
    end
  end
end
