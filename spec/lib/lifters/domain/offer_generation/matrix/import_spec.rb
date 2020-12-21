# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::Matrix::Import do
  subject { described_class.new(path: "") }

  RSpec.shared_examples "target_questionnaire" do
    it "creates a questionnaire" do
      expect(Questionnaire.count).to eq(questionnairies_count)
      expect(target_questionnaire.identifier).to eq("questionnaire_ident")
    end

    it "creates an offer automation" do
      offer_automations = target_questionnaire.offer_automations
      expect(offer_automations.count).to eq(1)

      offer_automation = offer_automations.first
      expect(offer_automation.name).to eq("offer_automation_name")
      expect(offer_automation.state).to eq("inactive")
    end

    it "creates an offer rule" do
      offer_automations = target_questionnaire.offer_automations
      offer_rules = offer_automations.first.offer_rules
      expect(offer_rules.count).to eq(1)

      offer_rule = offer_rules.first
      expect(offer_rule.name).to eq("offer_rule_name")
      expect(offer_rule.state).to eq("inactive")
      expect(offer_rule.activated).to eq(false)
      expect(offer_rule.plan_idents).to eq([nil, nil, nil])
    end
  end

  describe "#call" do
    let(:category) do
      create(:category, ident: "category_ident")
    end

    let(:question) do
      create(
        :questionnaire_question,
        question_identifier: "question_ident"
      )
    end

    let(:question_attr) do
      {
        "type" => "Questionnaire::TypeformQuestion",
        "question_text" => "QuestionText",
        "value_type" => "Text",
        "question_identifier" => "question_ident",
        "question_type" => "text"
      }
    end

    let(:questioning_attr) do
      {
        "sort_index" => 1,
        "question" => question_attr
      }
    end

    let(:default_coverage_features) do
      %w[
        money_dckngssmm_18b679
        text_gltngsbrch_b19672
        text_lstngspflcht_6f44ba
      ]
    end

    let(:offer_rule_attr) do
      {
        "name" => "offer_rule_name",
        "state" => "active",
        "activated" => true
      }
    end

    let(:offer_automation_attr) do
      {
        "name" => "offer_automation_name",
        "state" => "active",
        "note_to_customer" => "note",
        "default_coverage_feature_idents" => default_coverage_features,
        "offer_rules" => [
          offer_rule_attr
        ]
      }
    end

    let(:questionnaire_attr) do
      {
        "identifier" => "questionnaire_ident",
        "category" => {"ident" => "category_ident"},
        "questionings" => [questioning_attr],
        "offer_automations" => [offer_automation_attr]
      }
    end

    let(:data) { [questionnaire_attr] }

    before do
      allow_any_instance_of(described_class).to receive(:load_data)
        .and_return(data)

      question
      category
    end

    context "with correct data" do
      let(:questionnairies_count) { 1 }
      let(:target_questionnaire) { Questionnaire.first }

      before { subject.call }

      include_examples "target_questionnaire"
    end

    context "when category doesn't exist" do
      before { category.destroy! }

      it "returns an error" do
        expect(subject.call).to eq(
          "questionnaire_ident" => [
            "Category 'category_ident' doesn't exist"
          ]
        )
      end
    end

    context "when active questionnaire exists" do
      let(:questionnairies_count) { 2 }
      let(:target_questionnaire) { Questionnaire.second }

      before do
        category.update(questionnaire: create(:questionnaire))
        subject.call
      end

      include_examples "target_questionnaire"
    end

    context "when there is a questionnaire with the same ident" do
      context "with the same questions as source" do
        let(:questionnairies_count) { 1 }
        let(:target_questionnaire) { Questionnaire.first }

        before do
          existing_questionnaire = create(
            :questionnaire,
            identifier: questionnaire_attr["identifier"],
            category: category
          )

          create(
            :questionnaire_questioning,
            questionnaire: existing_questionnaire,
            question: question
          )

          subject.call
        end

        include_examples "target_questionnaire"
      end

      context "with existing automations" do
        before do
          existing_questionnaire = create(
            :questionnaire,
            identifier: questionnaire_attr["identifier"],
            category: category
          )

          create(
            :questionnaire_questioning,
            questionnaire: existing_questionnaire,
            question: question
          )

          create(
            :offer_automation,
            questionnaire: existing_questionnaire,
            name: offer_automation_attr["name"]
          )
        end

        it "returns an error" do
          expect(subject.call).to eq(
            "questionnaire_ident" => [
              "Offer automations [offer_automation_name] exist"
            ]
          )
        end
      end
    end

    context "when offer automation with same name exists" do
      before { create(:offer_automation, name: "offer_automation_name") }

      it "returns an error" do
        expect(subject.call).to eq(
          "questionnaire_ident" => [
            "Offer automations [offer_automation_name] exist"
          ]
        )
      end
    end

    context "when offer rule with same name exists" do
      before { create(:offer_rule, name: "offer_rule_name") }

      it "returns an error" do
        expect(subject.call).to eq(
          "questionnaire_ident" => [
            "Offer rules [offer_rule_name] exist"
          ]
        )
      end
    end
  end
end
