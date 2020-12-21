# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::Matrix::Export do
  subject { described_class.new(path: "") }

  let(:category) do
    build_stubbed(
      :category,
      ident: "category_ident"
    )
  end

  let(:offer_rule) do
    build_stubbed(
      :offer_rule,
      name: "offer_rule_name"
    )
  end

  let(:offer_automation) do
    build_stubbed(
      :offer_automation,
      name: "offer_automation_name",
      offer_rules: [offer_rule]
    )
  end

  let(:questioning) do
    build_stubbed(
      :questionnaire_questioning,
      question: question
    )
  end

  let(:question) do
    build_stubbed(
      :questionnaire_question,
      question_text: "question_text"
    )
  end

  let(:questionnaire) do
    build_stubbed(
      :questionnaire,
      identifier: "questionnaire_id",
      name: "questionnaire_name",
      category: category,
      offer_automations: [offer_automation],
      questionings: [questioning]
    )
  end

  before do
    allow_any_instance_of(described_class).to receive(:save_data)
      .and_return(nil)

    allow_any_instance_of(Domain::OfferGeneration::MatrixRepository).to receive(:questionnaires_with_automations)
      .and_return([questionnaire])
  end

  describe "#call" do
    let(:expected_data) do
      [
        a_hash_including(
          "identifier" => "questionnaire_id",
          "name" => "questionnaire_name",
          "category" => a_hash_including("ident" => "category_ident"),
          "offer_automations" => a_collection_containing_exactly(
            a_hash_including(
              "name" => "offer_automation_name",
              "offer_rules" => a_collection_containing_exactly(
                a_hash_including(
                  "name" => "offer_rule_name"
                )
              )
            )
          ),
          "questionings" => a_collection_containing_exactly(
            a_hash_including(
              "question" => a_hash_including(
                "question_text" => "question_text"
              )
            )
          )
        )
      ]
    end

    it "returns data" do
      expect(subject.call).to match(expected_data)
    end
  end
end
