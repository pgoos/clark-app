# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::MatrixRepository, :integration do
  subject { described_class.new }

  describe "#questionnaires_with_automations" do
    let(:category_ident) { "category_ident" }

    let(:category) do
      create(
        :category,
        ident: category_ident
      )
    end

    let(:questionnaire) do
      create(
        :questionnaire,
        questionings: [questioning],
        category: category
      )
    end

    let(:questioning) do
      create(
        :questionnaire_questioning,
        question: question
      )
    end

    let(:question) do
      create(:questionnaire_question)
    end

    let(:offer_automation) do
      create(
        :offer_automation,
        questionnaire: questionnaire
      )
    end

    let(:offer_rule) do
      create(
        :offer_rule,
        offer_automation: offer_automation
      )
    end

    let!(:build_offer_rule) { offer_rule }

    context "with excluded category" do
      subject { described_class.new(excluded_categories: category.ident) }

      it "returns empty data" do
        expect(subject.questionnaires_with_automations).to eq([])
      end
    end

    context "without excluded category" do
      context "when questionnaire has an offer_automation" do
        it "returns data" do
          expect(subject.questionnaires_with_automations).to eq([questionnaire])
        end
      end

      context "when questionnaire doesn't have an offer_automation" do
        let!(:remove_automations) { questionnaire.offer_automations.delete_all }

        it "returns empty data" do
          expect(subject.questionnaires_with_automations).to eq([])
        end
      end
    end
  end

  describe "#plans_with_automations" do
    let(:category) { create(:category, ident: "category1") }

    let(:plan1) do
      create(
        :plan,
        category: category,
        state: "active",
        ident: "plan1"
      )
    end

    let(:plan2) do
      create(
        :plan,
        category: category,
        state: "active",
        ident: "plan2"
      )
    end

    let(:plan3) do
      create(
        :plan,
        category: category,
        state: "active",
        ident: "plan3"
      )
    end

    let!(:offer_rule) do
      create(
        :offer_rule,
        category: category,
        plan_idents: [
          plan1.ident,
          plan2.ident,
          plan3.ident
        ]
      )
    end

    context "with excluded category" do
      subject { described_class.new(excluded_categories: category.ident) }

      it "filters out this category" do
        expect(subject.plans_with_automations).to eq([])
      end
    end

    context "without excluded category" do
      it "returns plans" do
        expect(subject.plans_with_automations).to match_array([plan1, plan2, plan3])
      end
    end
  end

  describe "#rules_with_plans" do
    let(:category) { create(:category) }
    let!(:offer_rule) do
      create(
        :offer_rule,
        name: "rule1",
        category: category,
        plan_idents: [
          create(:plan, ident: "plan1", category: category).ident,
          create(:plan, ident: "plan2", category: category).ident,
          create(:plan, ident: "plan3", category: category).ident
        ]
      )
    end

    it "returns rules to plans mapping" do
      expect(subject.rules_with_plans).to eq(
        "rule1" => %w[plan1 plan2 plan3]
      )
    end
  end
end
