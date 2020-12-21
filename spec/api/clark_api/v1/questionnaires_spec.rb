# frozen_string_literal: true

require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe ClarkAPI::V1::Questionnaires, :integration do
  let(:category) { create(:category, :high_margin) }
  let(:question) { create(:custom_question) }
  let(:question2) { create(:custom_question) }
  let(:question3) { create(:multiple_choice_question) }
  let(:question4) { create(:free_text_question, metadata: {'text': {multiline: false}, jumps: [{"destination": {"id": "text_14735235"}, "conditions": "true"}]}) }
  let(:question5) { create(:date_question, question_identifier: "idea") }
  let(:question_without_metadata) { create(:free_text_question, metadata: nil, question_type: nil) }
  let(:questionnaire) { create(:bedarfscheck_questionnaire, questions: [question, question2, question5], category: category) }
  let(:questionnaire_no_category) { create(:bedarfscheck_questionnaire, questions: [question, question2, question5]) }
  let(:no_bedarfscheck_questionnaire) { create(:custom_questionnaire, questions: [question3, question4, question_without_metadata], category: category) }
  let(:qs_with_cat) { create(:custom_questionnaire, questions: [question3, question4, question_without_metadata], category: category) }
  let(:q_response) { create(:questionnaire_response, questionnaire: questionnaire) }
  let(:no_b_q_response) { create(:questionnaire_response, questionnaire: no_bedarfscheck_questionnaire) }
  let(:qs_with_margin_level) { create(:custom_questionnaire, questions: [question3, question4, question_without_metadata], category: category) }

  context "PATCH /questionnaire/:id/responses/:rid/answers" do
    context "parameter validation" do
      it "returns 404 if the questionnaire was not found" do
        payload = {answers: [{question_id: 12, answer: {text: "foo"}}]}
        json_patch "/api/questionnaires/not-existing-id/responses/not-exisiting-rid/answers", payload
        expect(response.status).to eq(404)
        expect(json_response.error).to eq("questionnaire not found")
      end

      it "returns 404 if the questionnaire response was not found" do
        payload = {answers: [{question_id: 12, answer: {text: "foo"}}]}
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/not-exisiting-rid/answers", payload
        expect(response.status).to eq(404)
        expect(json_response.error).to eq("questionnaire response not found")
      end

      it "returns 400 if no answers are provided" do
        payload = {answers: []}
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
        expect(response.status).to eq(400)
      end

      it "returns 400 if the items in the answers aray are not hashes" do
        payload = {answers: ["string"]}
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
        expect(response.status).to eq(400)
      end

      it "returns 400 if the question_id in an answer is missing" do
        payload = {answers: [
          {question_id: 12, answer: {text: "foo"}},
          {answer: {text: "bar"}}
        ]}
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
        expect(response.status).to eq(400)
      end

      it "returns 400 if the answer value in an answer is missing" do
        payload = {answers: [{question_id: 12, answer: {text: "foo"}}, {question_id: 13, answer: nil}]}
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload

        expect(response.status).to eq(400)
      end

      it "returns 400 if the question is not in the questionnaire" do
        payload = {answers: [{question_id: 4711, answer: {text: "foo"}}]}
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload

        expect(response.status).to eq(400)
        expect(json_response.error).to eq("question 4711 is not in the questionnaire")
      end

      it "returns 400 if the answer is not in the correct format for the question" do
        payload = {answers: [
          {question_id: question.question_identifier, answer: {text: "foo"}},
          {question_id: question2.question_identifier, answer: {value: "foo"}}
        ]}

        expect {
          json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
        }.not_to change { Questionnaire::Answer.count }

        expect(response.status).to eq(400)
        expect(json_response.error).to eq("answer for question #{question2.question_identifier} is not a valid Text value type")
      end
    end

    it "creates answer objects for the given questionnaire response" do
      payload = {answers: [
        {question_id: question.question_identifier, answer: {text: "foo"}},
        {question_id: question2.question_identifier, answer: {text: "bar"}}
      ]}

      expect {
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
      }.to change { Questionnaire::Answer.count }.from(0).to(2)
      q_response.reload

      expect(q_response.answers.first.answer["text"]).to eq("foo")
      expect(q_response.answers.first.question).to eq(question)

      expect(q_response.answers.second.answer["text"]).to eq("bar")
      expect(q_response.answers.second.question).to eq(question2)
    end

    it "advances response to in_progress and keeps it in this state" do
      payload1 = {answers: [{question_id: question.question_identifier, answer: {text: "foo"}}]}
      payload2 = {answers: [{question_id: question2.question_identifier, answer: {text: "bar"}}]}

      expect(q_response).to be_created
      json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload1
      q_response.reload
      expect(q_response).to be_in_progress
      expect(q_response.answers.count).to eq(1)

      json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload2
      q_response.reload
      expect(q_response).to be_in_progress
      expect(q_response.answers.count).to eq(2)
    end

    it "updates an answer instead of creating a new one, if one exists" do
      payload = {answers: [{question_id: question.question_identifier, answer: {text: "bar"}}]}

      q_response.create_answer!(question, text: "foo")

      expect {
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
      }.not_to change { Questionnaire::Answer.count }

      q_response.reload

      expect(q_response.answers.last.answer["text"]).to eq("bar")
    end

    it "throws a 404 if text answer instead of date" do
      payload = {answers: [{question_id: question5.question_identifier, answer: {text: "bar"}}]}
      json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
      expect(response.status).to eq(400)
      expect(json_response.error).to eq("Ungültiges Datum")
    end

    it "throws a 404 if invalid date format submitted" do
      payload = {answers: [{question_id: question5.question_identifier, answer: {text: "1990.06.26"}}]}
      json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
      expect(response.status).to eq(400)
      expect(json_response.error).to eq("Ungültiges Datum")
    end

    it "allows to submit the answer" do
      payload = {answers: [{question_id: question5.question_identifier, answer: {text: "06.05.1963"}}]}
      json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers", payload
      expect(response.status).to eq(200)
      expect(q_response.answers.last.answer["text"]).to eq("06.05.1963")
    end
  end

  context "GET /questionnaires/:id/responses/:rid/answers" do
    context "parameter validation" do
      it "returns 404 if the questionnaire was not found" do
        json_get "/api/questionnaires/not-existing-id/responses/not-exisiting-rid/answers"
        expect(response.status).to eq(404)
        expect(json_response.error).to eq("questionnaire not found")
      end

      it "returns 404 if the questionnaire response was not found" do
        json_get "/api/questionnaires/#{questionnaire.identifier}/responses/not-exisiting-rid/answers"
        expect(response.status).to eq(404)
        expect(json_response.error).to eq("questionnaire response not found")
      end
    end

    it "returns the response with answers" do
      q_response.create_answer!(question, text: "foo")
      q_response.create_answer!(question2, text: "bar")

      json_get "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/answers"

      expect(response.status).to eq(200)

      response_object = json_response.questionnaire_response
      expect(response_object.response_id).to eq(q_response.response_id)
      expect(response_object.state).to eq("in_progress")

      expect(response_object.answers.count).to eq(2)

      expect(response_object.answers.first.question_id).to eq(question.question_identifier)
      expect(response_object.answers.first.answer).to eq("foo")
      expect(response_object.answers.first.answer_raw.text).to eq("foo")

      expect(response_object.answers.second.question_id).to eq(question2.question_identifier)
      expect(response_object.answers.second.answer).to eq("bar")
      expect(response_object.answers.second.answer_raw.text).to eq("bar")
    end
  end

  context "PATCH /questionnaires/:id/responses/:rid/finish" do
    before do
      q_response.update(state: "in_progress")
    end

    context "parameter validation" do
      it "returns 404 if the questionnaire was not found" do
        json_patch "/api/questionnaires/not-existing-id/responses/not-exisiting-rid/finish"
        expect(response.status).to eq(404)
        expect(json_response.error).to eq("questionnaire not found")
      end

      it "returns 404 if the questionnaire response was not found" do
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/not-exisiting-rid/finish"
        expect(response.status).to eq(404)
        expect(json_response.error).to eq("questionnaire response not found")
      end
    end

    context "recommendation logic" do
      let!(:user) { create(:user, mandate: create(:mandate)) }

      before do
        login_as user, scope: :user
      end

      it "sets the questionnaire response to be analyzed" do
        json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/finish"

        q_response.reload
        expect(q_response).to be_analyzed
      end
    end

    describe "#opportunity creation" do
      subject { json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/finish" }

      let!(:user) { create(:user, :with_mandate) }
      let!(:q_response) { create(:questionnaire_response, questionnaire: questionnaire, mandate: user.mandate) }
      let!(:bedarfscheck_questionnaire) { create(:bedarfscheck_questionnaire, questions: [question, question2]) }

      before { login_as user, scope: :user }

      context "when questionnaire is bedarfscheck questionnaire" do
        let!(:questionnaire) { bedarfscheck_questionnaire }
      end

      context "when questionnaire is not bedarfscheck questionnaire" do
        let!(:questionnaire) { create(:custom_questionnaire, questions: [question3, question4, question_without_metadata]) }

        context "when questionnaire has a category" do
          let!(:category) { create(:category) }

          before { questionnaire.update(category: category) }

          context "when offers are generated" do
            it "calls the offer rule matrix" do
              expect(Domain::OfferGeneration::Matrix::CustomerWantsOffer).to receive(:call).with(q_response)
              json_patch "/api/questionnaires/#{questionnaire.identifier}/responses/#{q_response.response_id}/finish"
            end
          end

          context "when no opportunity for category exists" do
            it "creates a new opportunity for questionnaire response and an interaction" do
              expect { subject }.to change { q_response.reload.opportunity }
                .from(nil)
                .and change(Opportunity, :count)
                .by(1)
                .and change { Interaction::AnsweredQuestionnaire.count }
                .by(1)
              created_opportunity = Opportunity.last
              created_interaction = Interaction::AnsweredQuestionnaire.last
              expect(q_response.reload.opportunity).to eq(created_opportunity)

              expect(created_interaction.topic).to eq(created_opportunity)
              expect(created_interaction.questionnaire_response).to eq(q_response)
              expect(created_interaction.mandate).to eq(user.mandate)
              expect(created_interaction).to be_acknowledged

              questionnaire_json = JSON.parse(response.body)
              expect(questionnaire_json["questionnaire_response"]["opportunity_id"]).to eq(created_opportunity.id)
            end

            context "when an automated offer is created for the category" do
              let!(:offer) { create(:offer) }
              let(:existing_opportunity_source) { create(:questionnaire_response, questionnaire: questionnaire) }
              let!(:existing_opportunity) do
                create :opportunity, mandate: user.mandate, category: category, offer_id: offer.id,
                       source: existing_opportunity_source
              end

              it "adds the offer id to the response" do
                expect(q_response.opportunity).to be_nil
                expect { subject }.not_to change { Opportunity.count }
                expect(q_response.reload.opportunity).to eq(existing_opportunity)

                questionnaire_json = JSON.parse(response.body)
                expect(questionnaire_json["questionnaire_response"]["offer_id"]).to eq(offer.id)
              end
            end
          end

          context "when mandate has an unresolved opportunity for questionnaire category" do
            let(:existing_opportunity_source) { create(:questionnaire_response, questionnaire: questionnaire) }

            shared_examples "questionnaire response with existing opportunity" do
              it "reuses the existing opportunity for the questionnaire response but creates an interaction" do
                expect(q_response.opportunity).to be_nil
                expect { subject }.not_to change(Opportunity, :count)
                expect(q_response.reload.opportunity).to eq(existing_opportunity)

                created_interaction =
                  Interaction::AnsweredQuestionnaire.find_by(topic: existing_opportunity)
                expect(created_interaction).to be_present
                expect(created_interaction.questionnaire_response).to eq(q_response)
                expect(created_interaction.mandate).to eq(user.mandate)

                questionnaire_json = JSON.parse(response.body)
                expect(questionnaire_json["questionnaire_response"]["opportunity_id"]).to eq(existing_opportunity.id)
              end
            end

            shared_examples "questionnaire response without opportunity" do
              it "creates a new opportunity for the questionnaire response" do
                expect { subject }.to change(Opportunity, :count)
                expect(q_response.reload.opportunity).not_to eq existing_opportunity
              end
            end

            context "with created state" do
              let!(:existing_opportunity) do
                create :opportunity, :created, mandate: user.mandate, category: category,
                       source: existing_opportunity_source
              end

              it_behaves_like "questionnaire response with existing opportunity"
            end

            context "with initiation_phase state" do
              let!(:existing_opportunity) do
                create :opportunity, :initiation_phase, mandate: user.mandate, category: category,
                       source: existing_opportunity_source
              end

              it_behaves_like "questionnaire response with existing opportunity"
            end

            context "with offer_phase state" do
              let!(:existing_opportunity) do
                create :opportunity, :offer_phase, mandate: user.mandate, category: category,
                       source: existing_opportunity_source
              end

              it_behaves_like "questionnaire response with existing opportunity"
            end

            context "with completed state" do
              let!(:existing_opportunity) do
                create :opportunity, :completed, mandate: user.mandate, category: category,
                       source: existing_opportunity_source
              end

              it_behaves_like "questionnaire response without opportunity"
            end

            context "with lost state" do
              let!(:existing_opportunity) do
                create :opportunity, :lost, mandate: user.mandate, category: category,
                       source: existing_opportunity_source
              end

              it_behaves_like "questionnaire response without opportunity"
            end

            context "when answers aren't equal to the answers of existing opportunity" do
              let(:existing_opportunity_source) do
                create(:questionnaire_response, questionnaire: questionnaire, answers: [build(:questionnaire_answer)])
              end

              let!(:existing_opportunity) do
                create :opportunity, :offer_phase, mandate: user.mandate, category: category,
                       source: existing_opportunity_source
              end

              it_behaves_like "questionnaire response without opportunity"
            end
          end
        end
      end
    end
  end

  context "GET /questionaires/:id" do
    it "returns a questionaire" do
      json_get "/api/questionnaires/#{no_bedarfscheck_questionnaire.identifier}"
      expect(response.status).to eq(200)
      questionnaire_json = JSON.parse(response.body)
      expect(questionnaire_json["questionnaire"]["identifier"]).to eq(no_bedarfscheck_questionnaire.identifier)
    end

    it "returns a category name if it has one" do
      json_get "/api/questionnaires/#{qs_with_cat.identifier}"
      questionnaire_json = JSON.parse(response.body)
      expect(questionnaire_json["questionnaire"]["category_name_hyphenated"]).to eq(word_hypen(category.name))
    end

    it "returns nil if no category name" do
      json_get "/api/questionnaires/#{questionnaire_no_category.identifier}"
      questionnaire_json = JSON.parse(response.body)
      expect(questionnaire_json["questionnaire"]["category_name_hyphenated"]).to eq(nil)
    end

    it "has empty jumps field when no jumps defined" do
      json_get "/api/questionnaires/#{no_bedarfscheck_questionnaire.identifier}"
      questionnaire_json = JSON.parse(response.body)
      expect(questionnaire_json["questionnaire"]["questions"].first["jumps"]).to eq([])
    end

    it "can handle null in metadata" do
      json_get "/api/questionnaires/#{no_bedarfscheck_questionnaire.identifier}"
      questionnaire_json = JSON.parse(response.body)
      expect(questionnaire_json["questionnaire"]["questions"][2]["jumps"]).to eq([])
    end

    it "has filled jumps field when jumps defined" do
      json_get "/api/questionnaires/#{no_bedarfscheck_questionnaire.identifier}"
      questionnaire_json = JSON.parse(response.body)
      expect(questionnaire_json["questionnaire"]["questions"].second["jumps"]).not_to eq([])
    end

    it "has an empty life aspect" do
      json_get "/api/questionnaires/#{questionnaire_no_category.identifier}"
      questionnaire_json = JSON.parse(response.body)
      expect(questionnaire_json["questionnaire"]["life_aspect"]).to eq(nil)
      expect(questionnaire_json["questionnaire"]["optional_appointment"]).to be_falsey
    end

    it "has margin level" do
      json_get "/api/questionnaires/#{qs_with_margin_level.identifier}"
      questionnaire_json = JSON.parse(response.body)
      expect(questionnaire_json["questionnaire"]["margin_level"]).to eq("high")
    end
  end
end
