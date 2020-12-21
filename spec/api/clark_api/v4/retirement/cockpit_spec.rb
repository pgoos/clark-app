# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Retirement::Cockpit, :integration do
  shared_examples "having eligibility" do |state|
    it "exposes a state" do
      login_as user, scope: :user
      json_get_v4 "/api/retirement/cockpit/eligible"

      expect(response.status).to eq 200
      expect(json_response["state"]).to eq state
    end
  end

  let(:user) { create :user, mandate: mandate }
  let(:trait) { :created }
  let(:birthdate) { Date.new(1985, 1, 1) }
  let(:customer_state) { nil }
  let(:mandate) { create :mandate, trait, birthdate: birthdate, customer_state: customer_state }

  before do
    create :retirement_income_tax, income_tax_percentage: 3083
    create :retirement_elderly_deductible, deductible_max_amount_cents: 0, deductible_percentage: 0
    create :retirement_taxable_share, year: 2052, taxable_share_state_percentage: 10_000
    create :retirement_income_tax, income_cents: 2_400_000, income_tax_percentage: 1_613
  end

  describe "GET /api/retirement/cockpit/eligible" do
    context "when common customer" do
      context "freebie" do
        let(:trait) { :freebie }

        it_behaves_like "having eligibility", "MANDATE_NOT_SIGNED"
      end

      context "not_started" do
        let(:trait) { :not_started }

        it_behaves_like "having eligibility", "MANDATE_NOT_SIGNED"
      end

      context "in_creation" do
        let(:trait) { :in_creation }

        it_behaves_like "having eligibility", "MANDATE_NOT_SIGNED"
      end

      context "created" do
        let(:trait) { :created }

        it_behaves_like "having eligibility", "RETIREMENTCHECK_NOT_DONE"
      end

      context "accepted" do
        let(:trait) { :accepted }

        it_behaves_like "having eligibility", "RETIREMENTCHECK_NOT_DONE"
      end
    end

    context "when clark2 customer" do
      let(:customer_state) { "prospect" }

      context "freebie" do
        let(:trait) { :freebie }

        it_behaves_like "having eligibility", "MANDATE_NOT_SIGNED"
      end

      context "not_started" do
        let(:trait) { :not_started }

        it_behaves_like "having eligibility", "RETIREMENTCHECK_NOT_DONE"
      end

      context "in_creation" do
        let(:trait) { :in_creation }

        it_behaves_like "having eligibility", "RETIREMENTCHECK_NOT_DONE"
      end

      context "created" do
        let(:trait) { :created }

        it_behaves_like "having eligibility", "RETIREMENTCHECK_NOT_DONE"
      end

      context "accepted" do
        let(:trait) { :accepted }

        it_behaves_like "having eligibility", "RETIREMENTCHECK_NOT_DONE"
      end
    end

    context "when customer is already retired" do
      let(:mandate) { create :mandate, :created, birthdate: Time.zone.now - 70.years }

      it "exposes a state" do
        login_as user, scope: :user
        json_get_v4 "/api/retirement/cockpit/eligible"

        expect(json_response["state"]).to eq "TOO_OLD"
      end
    end

    context "when non-authorized" do
      it "responds with an error" do
        json_get_v4 "/api/retirement/cockpit/eligible"
        expect(response.status).to eq 401
      end
    end
  end

  describe "GET /api/retirement/cockpit/summary" do
    let(:mandate) { create :mandate, :created, birthdate: Date.parse("01.01.1985") }

    before do
      login_as user, scope: :user

      cockpit = create :retirement_cockpit, mandate: mandate, desired_income: 4_000
      create :profile_datum, :yearly_gross_income, value: { "text" => 50_000 }, mandate: mandate
      create :retirement_calculation_result, retirement_cockpit: cockpit

      Timecop.freeze(Date.new(2018, 11, 13))
    end

    after { Timecop.return }

    context "when calculation service is disabled" do
      it "responds with a summary for cockpit" do
        json_get_v4 "/api/retirement/cockpit/summary"
        expect(response.status).to eq 200
        expect(json_response).to eq(
          "id" => mandate.retirement_cockpit.id,
          "desired_income" => 4_000.0,
          "recommended_income" => 3_192.92
        )
      end
    end

    context "when calculation service is enabled" do
      before do
        allow(Domain::Retirement::Service).to(
          receive(:enabled?).and_return(true)
        )
      end

      it "responds with a summary for calculation" do
        json_get_v4 "/api/retirement/cockpit/summary"
        expect(response.status).to eq 200
        expect(json_response).to eq(
          "id" => mandate.retirement_cockpit.id,
          "desired_income" => 4_000.0,
          "recommended_income" => 150_000.0,
          "state" => "new"
        )
      end
    end
  end

  describe "PATH /api/retirement/cockpit/summary" do
    before { login_as user, scope: :user }

    it "updates a summary" do
      json_patch_v4 "/api/retirement/cockpit/summary", desired_income: 5_000
      expect(response.status).to eq 200
      expect(mandate.retirement_cockpit.desired_income_cents).to eq 500_000
    end

    context "with invalid params" do
      it "validates a presence" do
        json_patch_v4 "/api/retirement/cockpit/summary", other: 5_000
        expect(response.status).to eq 400
      end

      it "validates a type" do
        json_patch_v4 "/api/retirement/cockpit/summary", desired_income: "TMP"
        expect(response.status).to eq 400
      end
    end

    context "with null value" do
      it "resets a value" do
        json_patch_v4 "/api/retirement/cockpit/summary", desired_income: nil
        expect(response.status).to eq 200
        expect(json_response["desired_income"]).to be_nil
      end
    end
  end

  describe "GET /products" do
    before do
      profile_property = create(:profile_property, identifier: "text_brttnkmmn_bad238")
      create(:profile_datum, mandate: user.mandate, property: profile_property, value: { text: "50000" })

      login_as user, scope: :user
    end

    context "when customer has products" do
      let!(:category) { create :category, ident: "84a5fba0" }
      let!(:plan) { create :plan, category: category }
      let!(:product) { create :product, mandate: user.mandate, plan: plan }

      let!(:retirement_state_product) do
        create :retirement_state_product, product: product, state: :details_available
      end

      let!(:corp_product) { create :product, :direktversicherung, mandate: user.mandate }

      let!(:retirement_product) do
        create(
          :retirement_product,
          :direktversicherung_classic,
          product: corp_product,
          state: :details_available,
          document_date: Date.new(2004, 1, 1),
          surplus_retirement_income: 3_500
        )
      end

      before do
        Timecop.freeze(Date.new(2018, 11, 13))
      end

      after { Timecop.return }

      it "lists all retirement products" do
        json_get_v4 "/api/retirement/cockpit/products"

        expect(response.status).to eq 200

        expect(json_response["products"]).to match_array \
          [
            {
              id: product.id,
              state: product.state,
              retirement_product_state: product.retirement_product.state,
              category: {
                id: product.category.id,
                name: product.category.name,
                ident: product.category.ident
              },
              company: {
                name: product.company.name,
                logo: { url: product.company.logo.url }
              },
              subcompany: {
                id: product&.subcompany&.id,
                name: product&.subcompany&.name
              },
              income: 1398.38,
              income_currency: "EUR",
              premium_price: product.premium_price.to_f,
              premium_price_currency: product.premium_price_currency,
              premium_period: product.premium_period,
              contribution: 9.3,
              forecast: product.retirement_product.forecast
            },
            {
              id: corp_product.id,
              state: corp_product.state,
              retirement_product_state: corp_product.retirement_product.state,
              category: {
                id: corp_product.category.id,
                name: corp_product.category.name,
                ident: corp_product.category.ident
              },
              company: {
                name: corp_product.company.name,
                logo: { url: corp_product.company.logo.url }
              },
              subcompany: {
                id: corp_product&.subcompany&.id,
                name: corp_product&.subcompany&.name
              },
              income: 1725.74,
              income_currency: "EUR",
              premium_price: corp_product.premium_price.to_f,
              premium_price_currency: corp_product.premium_price_currency,
              premium_period: corp_product.premium_period,
              contribution: 0.0,
              forecast: corp_product.retirement_product.forecast
            }
          ]
      end
    end

    context "when customer has equity products" do
      before do
        create(:product, :retirement_equity_product, mandate: user.mandate)
      end

      it "filters it out from the list" do
        json_get_v4 "/api/retirement/cockpit/products"
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.fetch("products")).to be_empty
      end
    end

    context "when product does not have retirement extension" do
      before do
        category = create(:category, ident: "84a5fba0")
        plan = create(:plan, category: category)
        create(:product, mandate: user.mandate, plan: plan)
      end

      it "sets product retirement state as information_required" do
        json_get_v4 "/api/retirement/cockpit/products"
        expect(response.status).to eq 200
        expect(json_response["products"]).not_to be_empty
        expect(json_response["products"].first["retirement_product_state"]).to \
          eq "information_required"
      end
    end
  end

  describe "GET /recommendations" do
    let!(:private_category) { create :category, ident: "vorsorgeprivat" }
    let!(:statutory_category) { create :category, ident: "84a5fba0" }
    let!(:company_category) { create :category, ident: "1ded8a0f" }

    let!(:not_retirement_category) { create :category, ident: "3659e48a" }

    let!(:recommendation1) { create :recommendation, category: private_category, mandate: user.mandate }
    let!(:recommendation2) { create :recommendation, category: statutory_category, mandate: user.mandate }
    let!(:recommendation3) { create :recommendation, category: company_category, mandate: user.mandate }
    let!(:recommendation4) { create :recommendation, category: not_retirement_category, mandate: user.mandate }

    let!(:expected_recommendations) do
      [private_category.ident, statutory_category.ident, company_category.ident]
    end

    before do
      login_as user, scope: :user
    end

    it "list all retirement related recommendations" do
      json_get_v4 "/api/retirement/cockpit/recommendations"

      expect(response.status).to eq 200
    end

    it "matches private, state, and company idents" do
      json_get_v4 "/api/retirement/cockpit/recommendations"

      result = JSON.parse(response.body)["recommendation"]
      expect(result.count).to eq(3)

      result.each do |resp|
        expect(expected_recommendations).to include(resp.dig("category", "ident"))
      end
    end
  end

  describe "GET /api/retirement/appointments" do
    let!(:appointment) { create :appointment, mandate: user.mandate }
    let!(:opportunity) { create :opportunity, mandate: user.mandate, source: appointment }

    let!(:appointments) do
      create_list(:appointment, 2, mandate: user.mandate)
    end

    let(:expected_response) do
      {
        appointments:
          [
            {
              id: appointment.id,
              state: appointment.state,
              starts: appointment.starts,
              ends: appointment.ends,
              call_type: appointment.call_type
            }
          ]
      }.to_json
    end

    it "list all retirement-related appointments" do
      appointment.update!(appointable: opportunity)

      login_as(user, scope: :user)

      json_get_v4 "/api/retirement/cockpit/appointments"

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end
  end
end
