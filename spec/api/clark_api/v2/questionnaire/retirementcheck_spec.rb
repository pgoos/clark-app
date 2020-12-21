# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Questionnaires, :integration do
  let(:user) { create(:user, mandate: create(:mandate)) }
  let(:questionnaire) { create(:questionnaire, identifier: Questionnaire::RETIREMENTCHECK_IDENT) }
  let(:profile_property) { create(:profile_property, identifier: "text_brf_378369") }

  describe "PATCH/ api/questionnaires/retirementcheck/answers" do
    let(:question_1) { create(:questionnaire_question, question_identifier: "retirementcheck_annual_salary") }
    let(:question_2) do
      create(:questionnaire_question,
             question_identifier: "retirementcheck_occupation", profile_property: profile_property)
    end

    let(:answers_param) {
      [
        {question_id: "retirementcheck_annual_salary", answer: {text: "40000"}},
        {question_id: "retirementcheck_occupation", answer: {text: "..."}}
      ]
    }

    before do
      create(:questionnaire_response, questionnaire: questionnaire, mandate: user.mandate, state: :in_progress)
      create(:questionnaire_questioning, question: question_1, questionnaire: questionnaire)
      create(:questionnaire_questioning, question: question_2, questionnaire: questionnaire)
    end

    context "when not authenticated" do
      it "returns 401" do
        json_patch_v2 "/api/questionnaires/retirementcheck/answers", answers: answers_param

        expect(response.status).to eq(401)
        expect(json_response.error).to eq("not authenticated")
      end
    end

    context "when authenticated" do
      before { login_as(user, scope: :user) }

      it "returns ok state with proper params" do
        json_patch_v2 "/api/questionnaires/retirementcheck/answers", answers: answers_param

        expect(response.status).to eq(200)
      end

      it "compute answers to the questionnaire-response entity" do
        questionnaire_response = Questionnaire::Response.last
        expect(questionnaire_response.answers.count).to eq 0

        json_patch_v2 "/api/questionnaires/retirementcheck/answers", answers: answers_param

        expect(questionnaire_response.answers.count).to eq 2
      end

      context "when answer in the wrong format" do
        let(:answers_param) do
          [
            {answer: {text: ""}, question_id: "retirementcheck_annual_salary"}
          ]
        end
        let(:expected_response) { { error: "Antwort ist nicht gültig" }.to_json }

        it "returns an error" do
          json_patch_v2 "/api/questionnaires/retirementcheck/answers", answers: answers_param

          expect(response.status).to eq(400)
          expect(response.body).to eq(expected_response)
        end
      end

      context "when out of scope" do
        let(:recommendation) { instance_double(Domain::Retirement::Recommendation::Builder) }
        let(:answers_param) do
          [
            {answer: {text: "Schuler"}, question_id: "retirementcheck_occupation"}
          ]
        end

        before do
          allow(Domain::Retirement::Recommendation::Builder).to receive(:new).with(user.mandate) { recommendation }
          allow(recommendation).to receive(:call)
        end

        it "compute answers to the questionnaire-response entity" do
          json_patch_v2 "/api/questionnaires/retirementcheck/answers", answers: answers_param

          expect(response.status).to eq(200)
          expect(Questionnaire::Response.last).to be_canceled
        end

        it "recalculates recommendations" do
          json_patch_v2 "/api/questionnaires/retirementcheck/answers", answers: answers_param

          expect(response.status).to eq(200)
          expect(recommendation).to have_received(:call)
        end
      end
    end
  end

  describe "PATCH/ api/retirementcheck/finish" do
    context "when not authenticated" do
      it "returns 401" do
        json_patch_v2 "/api/questionnaires/retirementcheck/finish"

        expect(response.status).to eq(401)
        expect(json_response.error).to eq("not authenticated")
      end
    end

    context "when authenticated" do
      before do
        login_as(user, scope: :user)

        create(:questionnaire_response, questionnaire: questionnaire, mandate: user.mandate, state: :in_progress)
        create(:plan, ident: "brdb0998")
        create(:category, ident: "84a5fba0")
      end

      it "returns ok state with proper params" do
        json_patch_v2 "/api/questionnaires/retirementcheck/finish"
        questionnaire_response = Questionnaire::Response.last

        expect(response.status).to eq(200)
        expect(questionnaire_response.state).to eq "completed"
      end

      it "creates a new product" do
        expect(user.mandate.products.count).to be_zero

        json_patch_v2 "/api/questionnaires/retirementcheck/finish"

        expect(user.mandate.products.count).to eq(1)
      end

      it "tries to call the service" do
        expect(Domain::Retirement::Service).to(
          receive(:call)
        )
        json_patch_v2 "/api/questionnaires/retirementcheck/finish"
      end
    end
  end
end
