# frozen_string_literal: true

require "spec_helper"

require "structs/plan"
require "structs/offer_rule"
require "lifters/domain/offer_automations/retrieve_offer_rules"

RSpec.describe Domain::OfferAutomations::RetrieveOfferRules do
  describe "retrieve offer rules with their plans" do
    let(:plans_repository) { class_double("PlansRepository") }
    let(:offer_rules_repository) { class_double("OfferRulesRepository") }
    let(:offer_automation_id) { 1 }
    let(:service) { described_class.new(offer_rules_repository, plans_repository) }

    context "when success" do
      let(:offer_rules) do
        [
          Structs::OfferRule.new(
            name: "name",
            state: "state",
            activated: true,
            answer_values: {},
            plan_idents: ["ident-1"],
            plans: [],
            offer_automation_id: 1,
          )
        ]
      end

      let(:plans) do
        [
          Structs::Plan.new(
            ident: "ident-1",
            name: "Plan 1",
            company_name: "Company Name 1",
          ),
          Structs::Plan.new(
            ident: "ident-2",
            name: "Plan 2",
            company_name: "Company Name 2",
          ),
        ]
      end

      before do
        allow(offer_rules_repository).to receive(:all_sorted_by_ascending_name).and_return(offer_rules)
        allow(plans_repository).to receive(:all_by).and_return(plans)
      end

      it "returns offer rules with correct plans" do
        offer_rules = service.call(offer_automation_id)

        of = offer_rules.first
        expect(of.plans.map(&:ident)).to eq of.plan_idents
        expect(of.plans.length).to be(1)
      end
    end
  end
end
