# frozen_string_literal: true

require "rails_helper"
require "softfair/household_contents/comparison_calculator"
require "softfair/household_contents/results_mapper"

RSpec.describe Domain::OfferGeneration::HouseholdContents::HouseholdOfferFromComparison do
  let(:admin) { create(:admin) }
  let(:mandate) { create(:mandate, :accepted) }
  let(:accept_event) do
    {
      entity:     mandate,
      action:     "accept",
      created_at: 25.hours.ago,
      person:     admin
    }
  end
  let!(:accepted_mandate_event) { BusinessEvent.create(accept_event) }

  let(:category) { create(:category, ident: "e251294f") }
  let!(:household_opportunity) { create(:opportunity, category: category, mandate: mandate) }
  let(:gkv_category) { create(:category_gkv) }
  let!(:gkv_opportunity) { create(:opportunity, category: gkv_category, mandate: mandate) }

  context "candidates" do
    it "selects the right candidates" do
      expect(subject.candidates).to eq([household_opportunity])
    end

    it "rejects opportunities that have already been processed" do
      create(:business_event,
             entity_type: household_opportunity.class.name,
             entity_id:   household_opportunity.id,
             action:      "automation_run")
      expect(subject.candidates).to eq([])
    end

    context "when candidates is invalid" do
      let(:mandate) { create(:invalid_mandate) }

      it "rejects invalid candidates" do
        expect(subject.candidates).to eq([])
      end
    end
  end

  context "integration" do
    let(:softfair_response) { File.open("#{FIXTURE_DIR}/household/softfair_response.xml").read }
    let(:plan1) { create(:plan, ident: "ident1", category: category) }
    let(:plan2) { create(:plan, ident: "ident2", category: category) }
    let(:plan3) { create(:plan, ident: "ident3", category: category) }

    let(:plan_price1) { { premium_price_cents: 200 } }
    let(:plan_price2) { { premium_price_cents: 300 } }
    let(:plan_price3) { { premium_price_cents: 400 } }

    let(:offer_plans) { [plan1, plan2, plan3] }

    # System prerequisites
    let!(:admin) { create(:admin) }

    # Rule metadata
    let(:subject) { described_class }
    let(:expected_name) { "HOUSEHOLD_OFFER_FROM_COMPARISON" }
    let(:limit) { }

    # Situation Specification
    let(:intent_class) { Platform::RuleEngineV3::Flows::CreateOffer }
    let(:intent_options) do
      auto_context_class = Domain::OfferGeneration::HouseholdContents::HouseholdAutomationContext
      {
        candidate_context: auto_context_class.new(
          Domain::OfferGeneration::HouseholdContents::HouseholdQuestionnaireAdapter.new(
            household_opportunity.source
          )
        )
      }
    end

    # Candidate specifications
    let(:candidate) { household_opportunity }
    let(:candidates) do
      {
        household_opportunity => true
      }
    end

    let(:response_config) {
      {
        "number_37786506" => "50",
        "list_37786665" => "In einem Mehrfamilienhaus",
        "list_37786731" => "Ja",
        "list_37787025" => "",
        "list_37787300" => "Keine Schäden",
        "date_37785818" => ""
      }
    }

    let(:questionnaire_response) do
      response = instance_double(Questionnaire::Response)
      response_config.each_pair do |question_id, response_value|
        allow(response).to receive(:extract_normalized_answer)
          .with(question_id).and_return(response_value)
      end
      response
    end

    before do
      allow(household_opportunity).to receive(:source).and_return(questionnaire_response)
      allow(questionnaire_response).to receive(:mandate).and_return(household_opportunity.mandate)
      allow(questionnaire_response).to receive(:category).and_return(household_opportunity.category)
      allow_any_instance_of(Softfair::HouseholdContents::ComparisonCalculator)
        .to receive(:generate_comparison).and_return(softfair_response)
      allow_any_instance_of(Softfair::HouseholdContents::ResultsMapper)
        .to receive(:generate_offer_plans).and_return("")
      allow_any_instance_of(Domain::OfferGeneration::HouseholdContents::HouseholdAutomationContext)
        .to receive(:comparison_results).and_return(%w[plan1 plan2 plan3])
      allow_any_instance_of(Domain::OfferGeneration::HouseholdContents::HouseholdAutomationContext)
        .to receive(:offer_plans).and_return(offer_plans)
      allow_any_instance_of(Domain::OfferGeneration::HouseholdContents::HouseholdAutomationContext)
        .to receive(:product_attributes) \
        .and_return(plan1.ident => plan_price1, plan2.ident => plan_price2, plan3.ident => plan_price3)
    end

    it_behaves_like "v4 automation", %i[skip_applicable candidate_context]

    it "builds an offer" do
      create(:feature_switch,
             key: Features::AUTOMATED_HOUSEHOLD_OFFER_FROM_COMPARISON,
             active: true)

      expected_plans = [
        {
          plan_ident: plan1.ident, offer_option_type: :top_cover_and_price, is_recommended: true,
          debug_info: { plan_configs: [] }, product_attributes: plan_price1
        },
        {
          plan_ident: plan2.ident, offer_option_type: :top_cover, is_recommended: false,
          debug_info: { plan_configs: [] }, product_attributes: plan_price2
        },
        {
          plan_ident: plan3.ident, offer_option_type: :top_cover, is_recommended: false,
          debug_info: { plan_configs: [] }, product_attributes: plan_price3
        }
      ]

      expect(Platform::RuleEngineV3::Flows::CreateOffer).to receive(:new)
        .with(household_opportunity, subject.content_key, *expected_plans)
      subject.run([household_opportunity], admin)
    end
  end

  context "build plan hashes" do
    let!(:plan_cheap) { instance_double(Plan, ident: "ident_cheap", name: "cheap") }
    let!(:plan_x) { instance_double(Plan, ident: "ident_x", name: "plan X") }
    let!(:plan_y) { instance_double(Plan, ident: "ident_y", name: "plan Y") }
    let(:dummy_context) { double(debug_info: {}, product_attributes: {}) }

    # Ammerländer HR Comfort:
    # Let's keep those characters fuzzy, that are language or encoding dependent.
    let!(:plan_ammerlaender) do
      instance_double(Plan, ident: "sample_ident_ammerlaender", name: "Ammerl.nder HR .omfort")
    end

    context "#first_option" do
      let(:first_option) { subject.send(:first_option, [plan_cheap, plan_x, plan_y], dummy_context) }

      it "should build the top cover and price config" do
        expect(first_option[:offer_option_type]).to eq(:top_cover_and_price)
      end

      it "should recommend it" do
        expect(first_option[:is_recommended]).to eq(true)
      end

      it "should not recommend it, if there is a different plan with Ammerländer HR Comfort" do
        plan_list                = [plan_cheap, plan_ammerlaender, plan_y]
        option_1_not_recommended = subject.send(:first_option, plan_list, dummy_context)
        expect(option_1_not_recommended[:is_recommended]).to eq(false)
      end

      it "should recommend it, if it is Ammerländer HR Comfort" do
        first_option_recommended = subject.send(:first_option, [plan_ammerlaender, plan_x, plan_y], dummy_context)
        expect(first_option_recommended[:is_recommended]).to eq(true)
      end
    end

    context "#second_option" do
      let(:second_option) { subject.send(:second_option, [plan_cheap, plan_x, plan_y], dummy_context) }

      it "should build the top cover and price config" do
        expect(second_option[:offer_option_type]).to eq(:top_cover)
      end

      it "should not recommend it" do
        expect(second_option[:is_recommended]).to eq(false)
      end

      it "should recommend it, if it is Ammerländer HR Comfort" do
        plan_list                 = [plan_x, plan_ammerlaender, plan_y]
        second_option_recommended = subject.send(:second_option, plan_list, dummy_context)
        expect(second_option_recommended[:is_recommended]).to eq(true)
      end
    end

    context "#third_option" do
      let(:third_option) { subject.send(:third_option, [plan_cheap, plan_x, plan_y], dummy_context) }

      it "should build the top cover and price config" do
        expect(third_option[:offer_option_type]).to eq(:top_cover)
      end

      it "should not recommend it" do
        expect(third_option[:is_recommended]).to eq(false)
      end

      it "should recommend it, if it is Ammerländer HR Comfort" do
        third_option_recommended = subject.send(:third_option, [plan_x, plan_y, plan_ammerlaender], dummy_context)
        expect(third_option_recommended[:is_recommended]).to eq(true)
      end
    end
  end
end
