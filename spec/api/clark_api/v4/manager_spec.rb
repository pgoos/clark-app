# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V4::Manager, :integration do
  let(:user) { create(:user, mandate: create(:mandate)) }
  let(:analysis_state) { "details_missing" }

  it "returns HTTP 401 if the user is not singed in" do
    json_get_v4 "/api/manager"
    expect(response.status).to eq(401)
  end

  context "logged in" do
    let(:mandate) { user.mandate }
    let(:response_obj) { double :response_obj }

    before do
      create(:category, ident: "4fb3e303")
      create(:category, ident: "3659e48a")
      create(:bu_category)
      login_as(user, scope: :user)

      allow(Customer).to receive(:instant_advice_permitted?).and_return(response_obj)
      allow(response_obj).to receive(:failure?).and_return(false)
    end

    it "returns HTTP 200 if signed in" do
      json_get_v4 "/api/manager"

      expect(response.status).to eq(200)
    end

    context "with data" do
      let(:total_evaluation_value) { I18n.t("composites.contracts.constituents.instant_advice.mapping.average") }

      it "should deliver the cockpit json v4" do
        plan1 = create(:plan)
        plan2 = create(:plan)

        plan1.category.update!(questionnaire: create(:questionnaire))
        plan2.category.update!(questionnaire: create(:questionnaire))

        # Add some Inquiries
        inquiry1 = create(:inquiry)
        inquiry2 = create(:inquiry)
        inquiry1.inquiry_categories << create(:inquiry_category)
        inquiry2.inquiry_categories << create(:inquiry_category, :customer_not_insured_person)
        mandate.inquiries << inquiry1
        mandate.inquiries << inquiry2

        # Add some Opportunities
        mandate.opportunities << create(:opportunity_with_offer, mandate: mandate)
        mandate.opportunities << create(:opportunity_with_offer, mandate: mandate)

        # Add some Products
        mandate.products << (product1 = create(:product, plan: plan1, analysis_state: analysis_state))
        mandate.products << (product = create(:product, plan: plan2, analysis_state: analysis_state))

        # Add InstantAssessment
        create(:instant_assessment,
               category_ident: product.category_ident,
               company_ident: product.company.ident)

        create(:retirement_product, product: product)

        # Add some Recommendations
        mandate.recommendations << create(:recommendation, category: plan1.category)
        mandate.recommendations << create(:recommendation, category: plan2.category)

        # Create retirement product without plan that is created though
        # the documents upload
        create(
          :retirement_product,
          :created,
          :document_forecast,
          product: create(
            :product,
            :customer_provided,
            mandate: mandate,
            plan: nil
          )
        )

        json_get_v4 "/api/manager"
        json = json_response

        #
        # Here we're not supposed to assert all the nitty gritty details. It's about testing, if
        # the overall structure is there. Thus we test for the most important sub structures to
        # be present by checking an attribute quite typical for that structure.
        #
        # Specs for the details are done via unit tests. See spec/api/unit/...
        #

        expect(response.status).to eq 200

        expect(json.score).to eq(mandate.score)

        expect(json.life_aspect_score).to be_a(Hash)
        # TODO: test setup for: expect(json_response.life_aspect_score).not_to be_empty

        expect(json.life_aspect_priorities).to be_a(Hash)
        expect(json.life_aspect_priorities).not_to be_empty

        expect(json.products_yearly_total.value).to be_an(Integer)
        expect(json.products_yearly_total.currency).to eq("EUR")

        expect(json.products_monthly_total.value).to be_an(Integer)
        expect(json.products_monthly_total.currency).to eq("EUR")

        expect(json.inquiries).to be_an(Array)
        expect(json.inquiries.first&.inquiry_categories).to be_an(Array)
        expect(json.inquiries.first&.inquiry_categories&.first)
          .to include(:category_ident, :documents, :cancellation_cause)

        expect(json.opportunities).to be_an(Array)
        expect(json.opportunities.first.offer_id).to be_an(Integer)

        expect(json.products).to be_an(Array)
        expect(json.products.count).to eq 2
        json.products.each do |product|
          expect(product.plan_name).to be_a(String)
          expect(product.plan_name).to be_present
          expect(product.analysis_state).to eq(analysis_state)
          expect(product.shared).to be_in([true, false])
        end

        product = json.products.find { |p| p.retirement_product.present? }
        expect(product).to be_present
        expect(product.retirement_product.state).to be_present
        expect(product.retirement_product.forecast).to be_present
        expect(product.total_evaluation).to eq(total_evaluation_value)

        product_without_instance_advice = json.products.find { |p| p.id == product1.id }
        expect(product_without_instance_advice.total_evaluation).to be_nil

        expect(json.recommendations).to be_an(Array)
        expect(json.recommendations.first.questionnaire_identifier).to be_a(String)
        expect(json.recommendations.first.questionnaire_identifier).not_to be_empty

        expect(json.offers).to be_an(Array)
        expect(json.offers.first.cheapest_option_price.value).to be_an(Integer)
        expect(json.offers.first.cheapest_option_price.currency).to eq("EUR")

        # not putting much effort here. deprecated:
        expect(json.categories).to be_an(Array)
        expect(json.categories).not_to be_empty
        expect(json.bu_category).to be_a(Hash)
        expect(json.bu_category).not_to be_empty

        expect(json_response.short_recommendations).to eq(false)
      end
    end
  end
end
