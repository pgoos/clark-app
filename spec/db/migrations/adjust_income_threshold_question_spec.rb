# encoding : utf-8
# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "adjust_income_threshold_question"

describe AdjustIncomeThresholdQuestion, :integration do
  describe "#data" do
    let(:retirementcheck) { create(:retirementcheck) }
    let(:bedarfscheck) { create(:bedarfscheck_questionnaire) }
    let(:metadata) do
      {
        multiple_choice:
          {
            multiple: true,
            choices: [
              {
                label: "Angestellter",
                shows:
                  [
                    {type: "extra_option", label: "und verdiene bis zu 59.400€ Brutto jährlich", value: "bis 59.400"},
                    {type: "extra_option", label: "und verdiene über 59.400€ Brutto jährlich", value: "uber 59.400"},
                    {type: "question", value: "#{key}_job_title"},
                    {type: "question", value: "#{key}_health_insurance_type"}
                  ],
                value: "Angestellter",
                position: 0
              }
            ]
          }
      }
    end
    let(:option1) do
      {
        label: "und verdiene bis zu 60.750€ Brutto jährlich",
        value: "bis 60.750"
      }
    end
    let(:option2) do
      {
        label: "und verdiene über 60.750€ Brutto jährlich",
        value: "uber 60.750"
      }
    end

    context "when retirement" do
      let(:key) { "retirement" }

      before do
        question = create(:multiple_choice_question_custom, metadata: metadata, question_identifier: "retirement_job")
        create(:questionnaire_questioning, question: question, questionnaire: retirementcheck)

        subject.data
      end

      it "updates Angestellter" do
        question = Questionnaire::Question.find_by(question_identifier: "retirement_job")
        option = question.metadata.dig("multiple_choice", "choices")[0]["shows"]

        expect(option[0]["label"]).to eq option1[:label]
        expect(option[0]["value"]).to eq option1[:value]
        expect(option[1]["label"]).to eq option2[:label]
        expect(option[1]["value"]).to eq option2[:value]
      end
    end

    context "when bedarfs" do
      let(:key) { "demand" }

      before do
        question = create(:multiple_choice_question_custom, metadata: metadata, question_identifier: "demand_job")
        create(:questionnaire_questioning, question: question, questionnaire: bedarfscheck)

        subject.data
      end

      it "updates Angestellter" do
        question = Questionnaire::Question.find_by(question_identifier: "demand_job")
        option = question.metadata.dig("multiple_choice", "choices")[0]["shows"]

        expect(option[0]["label"]).to eq option1[:label]
        expect(option[0]["value"]).to eq option1[:value]
        expect(option[1]["label"]).to eq option2[:label]
        expect(option[1]["value"]).to eq option2[:value]
      end
    end
  end

  describe "#rollback" do
    it "does not raise an exception" do
      expect { subject.data }.not_to raise_exception
    end
  end
end
