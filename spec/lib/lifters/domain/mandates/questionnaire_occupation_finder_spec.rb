# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::QuestionnaireOccupationFinder do
  subject { described_class.new(mandate) }

  context "when the mandate is employed in a public service" do
    let(:sector_question_text) { I18n.t("questionnaire.occupation.sector_question") }
    let(:sector_answer_text) { I18n.t("questionnaire.occupation.public_sector_answer") }
    let(:occupation_text) { I18n.t("questionnaire.occupation.job_question") }

    let(:mandate) { create(:mandate) }
    let!(:response) { create(:questionnaire_response, mandate: mandate, answers: [sector_answer, occupation_answer]) }
    let(:sector_answer) do
      create(:questionnaire_answer, question_text: sector_question_text, answer: {text: sector_answer_text})
    end

    let(:occupation_answer) do
      create(:questionnaire_answer, question_text: occupation_text, answer: {text: "Job"})
    end

    it "returns the correct occupation" do
      expect(subject.find_occupation).to eq "Job"
    end

    context "when there isn't a job answer" do
      let!(:response) { create(:questionnaire_response, mandate: mandate, answers: [sector_answer]) }

      it "returns a nil occupation" do
        expect(subject.find_occupation).to eq nil
      end
    end

    context "when there are multiple responses and the most recent doesn't have an occupation" do
      let!(:response) { create(:questionnaire_response, mandate: mandate, answers: [sector_answer, occupation_answer]) }
      let!(:other_response) { create(:questionnaire_response, mandate: mandate, answers: [occupation_answer]) }

      it "returns a nil occupation" do
        expect(subject.find_occupation).to eq nil
      end
    end

    context "when mandate doesn't work in public sector" do
      let!(:response) { create(:questionnaire_response, mandate: mandate, answers: [sector_answer, occupation_answer]) }

      let(:sector_answer) do
        create(:questionnaire_answer, question_text: sector_question_text, answer: {text: "Other Sector"})
      end

      it "returns a nil occupation" do
        expect(subject.find_occupation).to eq nil
      end
    end
  end
end
