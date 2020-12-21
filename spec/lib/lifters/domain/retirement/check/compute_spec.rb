# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Check::Compute, :integration do
  let(:mandate) { create :mandate }
  let(:questionnaire) { create :questionnaire, identifier: "retirementcheck" }
  let(:question) { create(:questionnaire_question, question_identifier: "retirementcheck_1") }
  let(:answers) do
    [{answer: {text: "text"}, question_id: "retirementcheck_1"}]
  end

  before do
    @questionnaire_response = create(:questionnaire_response, mandate: mandate, questionnaire: questionnaire)
    create(:questionnaire_questioning, question: question, questionnaire: questionnaire)
  end

  describe "#call" do
    context "when validation fails" do
      let(:answer_check) do
        instance_double(Domain::Retirement::Check::Answer, valid?: false, errors: ["Validation error!"])
      end

      before do
        allow(Domain::Retirement::Check::Answer)
          .to receive(:new)
          .with(mandate, @questionnaire_response, answers.first)
          .and_return(answer_check)
      end

      it "returns validation errors" do
        compute = described_class.new(mandate)
        compute.call(answers)
        expect(compute.errors.flatten).to eq ["Validation error!"]
      end

      it "does not create answer" do
        expect { described_class.new(mandate).call(answers) }.to change { Questionnaire::Answer.count }.by(0)
      end
    end

    context "with only 1 answer" do
      it "adds mandate's answer to Questionnaire::Response" do
        expect { described_class.new(mandate).call(answers) }.to change { Questionnaire::Answer.count }.by(1)
      end

      it "sets questionnaire_response state to in_progress" do
        described_class.new(mandate).call(answers)
        expect(@questionnaire_response.reload.state).to eq "in_progress"
      end
    end

    context "with more than 1 answer" do
      let(:question_2) { create(:questionnaire_question, question_identifier: "retirementcheck_2") }
      let(:answers) do
        [
          {answer: {text: "text1"}, question_id: "retirementcheck_1"},
          {answer: {text: "text2"}, question_id: "retirementcheck_2"}
        ]
      end

      before do
        create(:questionnaire_questioning, question: question_2, questionnaire: questionnaire)
      end

      it "adds all mandate's answer to Questionnaire::Response" do
        expect { described_class.new(mandate).call(answers) }.to change { Questionnaire::Answer.count }.by(2)
      end
    end

    context "when answer is either birthdate or gender" do
      let(:question) { create(:questionnaire_question, question_identifier: "retirementcheck_birthdate") }
      let(:question_2) { create(:questionnaire_question, question_identifier: "retirementcheck_gender") }
      let(:answers) do
        [
          {answer: {text: "01.01.1990"}, question_id: "retirementcheck_birthdate"},
          {answer: {text: "female"}, question_id: "retirementcheck_gender"}
        ]
      end

      before do
        create(:questionnaire_questioning, question: question_2, questionnaire: questionnaire)
      end

      it "updates mandates data" do
        described_class.new(mandate).call(answers)
        mandate.reload
        expect(mandate.birthdate.to_date).to eq Date.parse("01.01.1990")
        expect(mandate.gender).to eq "female"
      end
    end
  end
end
