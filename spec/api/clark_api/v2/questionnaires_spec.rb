# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Questionnaires, :clark_with_master_data do
  let(:user) { create(:user, mandate: create(:mandate)) }
  let!(:bedarfcheck_questionnaire) {
    Questionnaire.find_by(identifier: Questionnaire::BEDARFCHECK_IDENT)
  }

  before(:all) do
    Core::MainSeeder.load_bedarfcheck_questionnaire
  end

  after(:all) do
    questionnaire_for_cleanup = Questionnaire.find_by(identifier: Questionnaire::BEDARFCHECK_IDENT)
    questionnaire_for_cleanup.questions.each do |question|
      question.questionings.map(&:destroy!)
    end
    questionnaire_for_cleanup.questions.map(&:destroy!)
    questionnaire_for_cleanup.destroy!
  end

  context "POST /api/questionnaires/:id/responses" do
    it "raises error if the user is not authenticated" do
      json_post_v2 "/api/questionnaires/23/responses"

      expect(response.status).to eq(401)
      expect(json_response.error).to eq("not authenticated")
    end

    context "logged in" do
      before { login_as(user, scope: :user) }

      context "when questionnaire exists" do
        let(:questionnaire) { create(:questionnaire, questionnaire_type: "typeform", identifier: "dummy_ident") }
        let(:api_endpoint) { "/api/questionnaires/#{questionnaire.identifier}/responses" }

        context "without questionnaire_source param" do
          it "creates the reponse and returns with the response ID" do
            json_post_v2 api_endpoint

            expect(response.status).to eq(201)
            expect(json_response.success).to be_truthy
            expect(json_response.response_id).not_to be_nil
            expect(json_response.id).not_to be_nil
            expect(Questionnaire::Response.find(json_response.id).questionnaire_source).to eq(nil)
          end
        end

        context "with questionnaire_source param" do
          let(:questionnaire_source) { "seo" }

          it "creates the reponse and stores questionnaire_source" do
            json_post_v2 api_endpoint, questionnaire_source: questionnaire_source

            expect(response.status).to eq(201)
            expect(Questionnaire::Response.find(json_response.id).questionnaire_source).to eq(questionnaire_source)
          end
        end
      end

      context "when questionnaire doesn't exist" do
        it "returns 404" do
          json_post_v2 "/api/questionnaires/23/responses"

          expect(response.status).to eq(404)
          expect(json_response.success).to be_falsey
          expect(json_response.response_id).to be_nil
        end
      end
    end
  end

  context "PATCH /api/questionnaires/bedarfcheck/answers" do
    let(:answers_param) {
      [
        {question_id: "demand_vehicle", answer: {text: "auto"}},
        {question_id: "demand_livingplace", answer: {text: "gemietetes Haus"}}
      ]
    }

    it "errors if the user is not authenticated" do
      json_patch_v2 "/api/questionnaires/bedarfcheck/answers", answers: answers_param

      expect(response.status).to eq(401)
      expect(json_response.error).to eq("not authenticated")
    end

    context "logged in" do
      before { login_as(user, scope: :user) }

      it "returns ok state with proper params" do
        json_patch_v2 "/api/questionnaires/bedarfcheck/answers", answers: answers_param
        expect(response.status).to eq(200)
      end

      it "creates a new questionnaire response" do
        expect {
          json_patch_v2 "/api/questionnaires/bedarfcheck/answers", answers: answers_param
        }.to change(Questionnaire::Response, :count).by(1)
      end

      it "creates a new questionnaire response for bedarfcheck" do
        json_patch_v2 "/api/questionnaires/bedarfcheck/answers", answers: answers_param

        latest_response = Questionnaire::Response.last

        expect(latest_response.questionnaire.identifier).to eq(Questionnaire::BEDARFCHECK_IDENT)
      end

      it "does not create a new questionnaire response and uses the latest open demand check one" do
        create(
          :questionnaire_response,
          questionnaire: bedarfcheck_questionnaire,
          mandate:       user.mandate
        )

        expect {
          json_patch_v2 "/api/questionnaires/bedarfcheck/answers", answers: answers_param
        }.not_to change(Questionnaire::Response, :count)
      end

      it "creates a new questionnaire response if there is a last but finished demandcheck response" do
        create(
          :questionnaire_response,
          questionnaire: bedarfcheck_questionnaire,
          mandate:       user.mandate,
          finished_at:   Time.now,
          state:         :completed
        )

        expect {
          json_patch_v2 "/api/questionnaires/bedarfcheck/answers", answers: answers_param
        }.to change(Questionnaire::Response, :count).by(1)
      end

      context "failure to map a question" do
        let(:answers_param) {
          [
            {question_id: "demand_vehicle", answer: {text: "auto"}},
            {question_id: "demand_livingplace", answer: {text: "gemietetes Haus"}},
            {question_id: "non existenet", answer: {text: "what ever"}}
          ]
        }

        it "returns 400" do
          json_patch_v2 "/api/questionnaires/bedarfcheck/answers", answers: answers_param
          expect(response.status).to eq(400)
        end

        it "rolls back the creation of a questionnaire response" do
          expect {
            json_patch_v2 "/api/questionnaires/bedarfcheck/answers", answers: answers_param
          }.not_to change(Questionnaire::Response, :count)
        end
      end

      context "failure to map an answer value type" do
        let(:answers_param_with_unmapped_answer) {
          [
            {question_id: "demand_vehicle", answer: {text: "auto"}},
            {question_id: "demand_livingplace", answer: {non_existent_value_type: "gemietetes Haus"}}
          ]
        }

        it "returns 400" do
          json_patch_v2 "/api/questionnaires/bedarfcheck/answers",
                        answers: answers_param_with_unmapped_answer


          expect(response.status).to eq(400)
        end

        it "rolls back the creation of a questionnaire response" do
          expect {
            json_patch_v2 "/api/questionnaires/bedarfcheck/answers",
                          answers: answers_param_with_unmapped_answer
          }.not_to change(Questionnaire::Response, :count)
        end
      end
    end
  end

  describe "PATCH /api/questionnaires/bedarfcheck/finish" do
    it "raises error if the user is not authenticated" do
      json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

      expect(response.status).to eq(401)
      expect(json_response.error).to eq("not authenticated")
    end

    context "logged in" do
      let(:builder) { instance_double(Domain::Retirement::Recommendation::Builder) }

      before { login_as(user, scope: :user) }

      it "responds with 400 if no bedarfcheck questionnaire response exists" do
        json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

        expect(response.status).to eq(400)
        expect(json_response.success).to be_falsey
        expect(json_response.error).to eq(I18n.t("api.errors.demand_check.could_not_find_response"))
      end

      it "responds with 400 if no bedarfcheck unfinished questionnaire response exists" do
        create(
          :questionnaire_response,
          questionnaire: bedarfcheck_questionnaire,
          mandate:       user.mandate,
          finished_at:   Time.now,
          state:         :completed
        )

        json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

        expect(response.status).to eq(400)
        expect(json_response.success).to be_falsey
        expect(json_response.error).to eq(I18n.t("api.errors.demand_check.could_not_find_response"))
      end

      context "has unfinished bedarfcheck questionnaire response" do
        let!(:another_questionnaire_response) do
          create(
            :questionnaire_response,
            questionnaire: bedarfcheck_questionnaire,
            mandate:       user.mandate,
            state:         :in_progress
          )
        end
        let!(:unfinished_questionnaire_response) {
          create(
            :questionnaire_response,
            questionnaire: bedarfcheck_questionnaire,
            mandate:       user.mandate,
            state:         :in_progress
          )
        }

        before do
          allow_any_instance_of(Domain::DemandCheck::RecommendationsBuilder)
            .to receive(:apply_rules).and_return([])
          allow_any_instance_of(Domain::DemandCheck::MandatoryRecommendations)
            .to receive(:apply_rules).and_return([])

          allow(Retirement::SetupJob).to receive(:perform_now).with(user.mandate_id)
          allow(Domain::Retirement::Recommendation::Builder).to receive(:new).with(user.mandate) { builder }
          allow(builder).to receive(:call)
        end

        it "will call recommendation builder" do
          expect_any_instance_of(Domain::DemandCheck::RecommendationsBuilder)
            .to receive(:apply_rules)

          json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

          expect(response.status).to eq(200)
        end

        it "creates state, private, and corporate recommendations" do
          json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

          expect(response.status).to eq(200)
          expect(builder).to have_received(:call)
        end

        it "will call placeholder logic" do
          expect_any_instance_of(Domain::DemandCheck::MandatoryRecommendations)
            .to receive(:apply_rules)

          json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

          expect(response.status).to eq(200)
        end

        it "will mark the questionnaire response as analyzed" do
          json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

          expect(unfinished_questionnaire_response.reload.finished_at).not_to be_nil
          expect(unfinished_questionnaire_response.state).to eq(:analyzed.to_s)
          expect(response.status).to eq(200)
        end

        it "triggers the calculation of retirement" do
          json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

          expect(user.mandate.retirement_cockpit).to be_a(Retirement::Cockpit)
        end

        it "enqueues Retirement::SetupJob" do
          json_patch_v2 "/api/questionnaires/bedarfcheck/finish"

          expect(Retirement::SetupJob).to have_received(:perform_now)
        end
      end
    end
  end
end
