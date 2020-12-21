# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DemandCheck::ResponseBuilder, :integration do
  let(:mandate) { build(:mandate, birthdate: nil, gender: nil) }

  describe "#answer_questionnaire" do
    subject { described_class.new mandate }

    let(:mandate) { create(:mandate) }
    let(:demandcheck) { create(:bedarfscheck_questionnaire) }
    let(:question) { create(:custom_question) }
    let(:validator) { double :validator, valid?: true }

    before do
      create(:questionnaire_questioning, question: question, questionnaire: demandcheck)
      allow(Domain::DemandCheck::AnswersValidator).to \
        receive(:new).and_return(validator)
    end

    it "validates the answers" do
      expect(validator).to receive(:valid?).with(question, "VALUE")
      subject.answer_questionnaire([{ question_id: question.question_identifier, answer: { text: "VALUE" } }])
    end

    it "persist answers" do
      response = create :questionnaire_response, mandate: mandate, questionnaire: demandcheck
      expect {
        subject.answer_questionnaire([{ question_id: question.question_identifier, answer: { text: "VALUE" } }])
      }.to change(response.answers, :count).by(1)
    end

    it "saves gender and birthdate to mandates" do
      birhtdate_question = create(:custom_question, question_identifier: "demand_birthdate")
      gender_question = create(:custom_question, question_identifier: "demand_gender")

      create(:questionnaire_questioning, question: birhtdate_question, questionnaire: demandcheck)
      create(:questionnaire_questioning, question: gender_question, questionnaire: demandcheck)

      subject.answer_questionnaire(
        [
          { question_id: "demand_birthdate", answer: { text: "01.01.1990" } },
          { question_id: "demand_gender", answer: { text: "male" } }
        ]
      )

      expect(mandate.reload.birthdate&.to_date).to eq Date.new(1990, 1, 1)
      expect(mandate.gender.to_s).to eq "male"
    end

    it "deletes profile data when the answer for optional question is empty" do
      profile_property = create(:profile_property, identifier: "text_brttnkmmn_bad238")
      hobby_question = create(:custom_question, question_identifier: "demand_hobby", required: false, profile_property: profile_property)
      create(:questionnaire_questioning, question: hobby_question, questionnaire: demandcheck)
      create(:profile_datum, mandate: mandate, property: profile_property, value: { text: "Some hobby" })

      expect {
        subject.answer_questionnaire([{ question_id: hobby_question.question_identifier, answer: { text: "" } }])
      }.to change(mandate.profile_data, :count).by(-1)
    end
  end

  describe "finalize" do
    it "returns validation error for user with empty birthdate" do
      expect(described_class.new(mandate).finalize).to eq(I18n.t("api.errors.demand_check.birthdate_is_empty"))
    end

    context "salesforce" do
      subject { described_class.new mandate }

      let(:mandate) { create(:mandate) }
      let(:demandcheck) { create(:bedarfscheck_questionnaire) }

      before do
        birhtdate_question = create(:custom_question, question_identifier: "demand_birthdate")
        gender_question = create(:custom_question, question_identifier: "demand_gender")

        create(:questionnaire_questioning, question: birhtdate_question, questionnaire: demandcheck)
        create(:questionnaire_questioning, question: gender_question, questionnaire: demandcheck)

        subject.answer_questionnaire(
          [
            { question_id: "demand_birthdate", answer: { text: "01.01.1990" } },
            { question_id: "demand_gender", answer: { text: "male" } }
          ]
        )
      end

      context "when mandate is accepted" do
        before do
          mandate.state = "accepted"
          mandate.save!
        end

        it "sends an event to salesforce" do
          allow(Settings.salesforce).to receive(:enable_send_events).and_return(true)

          mock_lamda = ->(args) { args }
          allow(::Salesforce::Container).to receive(:resolve)
            .with("public.interactors.perform_send_event_job")
            .and_return(mock_lamda)

          expect(::Salesforce::Container).to receive(:resolve)
          subject.finalize
        end
      end

      context "when mandate is not accepted" do
        it "sends an event to salesforce" do
          allow(Settings.salesforce).to receive(:enable_send_events).and_return(true)

          mock_lamda = ->(args) { args }
          allow(::Salesforce::Container).to receive(:resolve)
            .with("public.interactors.perform_send_event_job")
            .and_return(mock_lamda)

          expect(::Salesforce::Container).not_to receive(:resolve)
          subject.finalize
        end
      end
    end
  end
end
