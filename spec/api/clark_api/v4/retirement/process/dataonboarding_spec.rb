# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Retirement::Process::Dataonboarding, :integration do
  let(:user) { create :user, mandate: mandate }
  let(:mandate) { create :mandate }

  describe "PATCH /api/retirement/process/dataonboarding/state" do
    let(:product) { create :product, :state, mandate: mandate }

    let!(:retirement_product) do
      create :retirement_product, :state, :details_available, product: product
    end

    let(:params) do
      {
        guaranteed_pension_continueed_payment: "1034.87",
        surplus_retirement_income: "1310",
        guaranteed_pension_continueed_payment_payment_type: "monthly",
        surplus_retirement_income_payment_type: "annually"
      }
    end

    before do
      profile_property = create(:profile_property, identifier: "text_brttnkmmn_bad238")
      create(:profile_datum, mandate: user.mandate, property: profile_property, value: {text: "50000"})
      create :retirement_elderly_deductible, deductible_max_amount_cents: 0, deductible_percentage: 0
      create :retirement_taxable_share, year: 2052, taxable_share_state_percentage: 10_000
      create :retirement_income_tax, income_cents: 2_400_000, income_tax_percentage: 1_613

      login_as user, scope: :user

      json_patch_v4 "/api/retirement/process/dataonboarding/state", params
    end

    it "updates state product" do
      expect(response.status).to eq 200
      retirement_product.reload
      expect(retirement_product.guaranteed_pension_continueed_payment_cents).to eq 103_487
      expect(retirement_product.guaranteed_pension_continueed_payment_payment_type).to eq "monthly"
      expect(retirement_product.surplus_retirement_income_cents).to eq 131_000
      expect(retirement_product.surplus_retirement_income_payment_type).to eq "annually"
      expect(retirement_product.forecast).to eq "customer"
    end

    context "when product doesn't exist" do
      let!(:retirement_product) { nil }

      it "responds with an error" do
        expect(response.status).to eq 500
      end
    end

    context "when product is in information required state" do
      let!(:retirement_product) do
        create :retirement_product, :state, :information_required, product: product
      end

      it "updates state product" do
        expect(response.status).to eq 200
        retirement_product.reload
        expect(retirement_product.state).to eq "details_available"
        expect(retirement_product.forecast).to eq "customer"
      end
    end

    context "when surplus_retirement_income not provided" do
      let(:params) do
      {
        guaranteed_pension_continueed_payment: "1034.87",
        guaranteed_pension_continueed_payment_payment_type: "monthly",
        surplus_retirement_income_payment_type: "annually"
      }
    end

      it { expect(response).to be_bad_request }
    end

    context "with an invalid payment type" do
      let(:params) do
        {
          guaranteed_pension_continueed_payment: "1034.87",
          surplus_retirement_income: "1310",
          guaranteed_pension_continueed_payment_payment_type: "monthly",
          surplus_retirement_income_payment_type: "yearly"
        }
      end

      it "responds with an error" do
        expect(response.status).to eq 400
      end
    end
  end
end
