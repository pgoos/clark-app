# frozen_string_literal: true

# == Schema Information
#
# Table name: questionnaire_responses
#
#  id               :integer          not null, primary key
#  response_id      :string
#  questionnaire_id :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  mandate_id       :integer
#  finished_at      :datetime
#  state            :string           default("created")
#

require "rails_helper"

RSpec.describe Questionnaire::Response, type: :model do
  it_behaves_like "an auditable model"

  describe "state machine" do
    it 'is created in the "created" state' do
      expect(Questionnaire::Response.new).to be_created
    end

    context "created state" do
      let(:q_response) { create(:questionnaire_response, state: "created") }

      it 'can be advanced to "in_progress" state by answering a question' do
        expect(q_response.answer_question).to be_truthy
        expect(q_response).to be_in_progress
      end

      it "can be cancelled" do
        expect(q_response.cancel).to be_truthy
        expect(q_response).to be_canceled
      end

      it "does not react to other events" do
        expect(q_response.finish).to be_falsey
        expect(q_response.analyze).to be_falsey
      end
    end

    context "in_progress state" do
      let(:q_response) { create(:questionnaire_response, state: "in_progress") }

      it 'stays "in_progress" by answering a question' do
        expect(q_response.answer_question).to be_truthy
        expect(q_response).to be_in_progress
      end

      it "can be cancelled" do
        expect(q_response.cancel).to be_truthy
        expect(q_response).to be_canceled
      end

      it "can be finished" do
        listener = double("Domain::Tracking::AdjustEventsObserver")
        q_response.subscribe(listener)

        expect(listener).to receive(:send_adjust_demand_check_finished_tracking).with(q_response.mandate)

        expect(q_response.finish).to be_truthy
        expect(q_response).to be_completed
      end

      it "does not react to other events" do
        expect(q_response.analyze).to be_falsey
      end
    end

    context "completed state" do
      let(:q_response) { create(:questionnaire_response, state: "completed") }

      it "can be analyzed" do
        expect(q_response.analyze).to be_truthy
        expect(q_response).to be_analyzed
      end

      it "can be cancelled" do
        expect(q_response.cancel).to be_truthy
        expect(q_response).to be_canceled
      end

      it "does not react to other events" do
        expect(q_response.finish).to be_falsey
        expect(q_response.answer_question).to be_falsey
      end
    end

    context "canceled state" do
      let(:q_response) { create(:questionnaire_response, state: "canceled") }

      it "does not react to any events" do
        expect(q_response.finish).to be_falsey
        expect(q_response.answer_question).to be_falsey
        expect(q_response.analyze).to be_falsey
        expect(q_response.cancel).to be_falsey
      end
    end

    it "sets finished_at when the questionnaire is finished" do
      q_response = create(:questionnaire_response, state: "in_progress")

      Timecop.freeze do
        q_response.finish
        expect(q_response.finished_at).to eq(DateTime.current)
      end
    end
  end

  it { expect(subject).to belong_to :questionnaire }

  it { expect(subject).to validate_presence_of(:mandate_id) }
  it { expect(subject).to validate_presence_of(:response_id) }
  it { expect(subject).to validate_presence_of(:questionnaire) }
  it { expect(subject).to have_db_column(:questionnaire_source).of_type(:string) }

  it "delegates #questionnaire_identifier to the questionnaire" do
    identifier = "quest_ident_#{rand}"
    subject.questionnaire = FactoryBot.build(:questionnaire, identifier: identifier)
    expect(subject.questionnaire_identifier).to eq(identifier)
  end

  describe "#create_answer!" do
    let(:question) { create(:typeform_question) }
    let(:questions) { [question] }
    let(:questionnaire) { create(:questionnaire, questions: questions) }
    let(:response) { create(:questionnaire_response, questionnaire: questionnaire) }

    it "creates an answer object for the current response" do
      expect {
        response.create_answer!(question, ValueTypes::Text.new("Meine Antwort"))
      }.to change { Questionnaire::Answer.count }.from(0).to(1)
    end

    it "changes the answer if a question was already answered in the current response" do
      response.answers.create(question: question, answer: ValueTypes::Text.new("Alte Antwort"), question_text: question.question_text)
      expect {
        response.create_answer!(question, ValueTypes::Text.new("Neue Antwort"))
      }.not_to change { Questionnaire::Answer.count }

      expect(response.answers.last.answer.text).to eq("Neue Antwort")
    end

    it "advances the response from created to in_progress" do
      expect {
        response.create_answer!(question, ValueTypes::Text.new("Meine Antwort"))
      }.to change(response, :state).from("created").to("in_progress")
    end

    it "keeps response in in_progress state" do
      response.state = "in_progress"
      expect {
        response.create_answer!(question, ValueTypes::Text.new("Meine Antwort"))
      }.not_to change(response, :state)
    end

    it "updates profile data if a mandate is present and question is linked to profile attribute" do
      profile_property = ProfileProperty.create(name: "Eine Info", description: "Irgendwas", value_type: "Text")
      question.update(profile_property: profile_property)

      expect(profile_property).to receive(:update_profile_for).with(response.mandate, ValueTypes::Text.new("Meine Antwort"), source: "questionnaire_response-#{response.id}")

      response.create_answer!(question, ValueTypes::Text.new("Meine Antwort"))
    end

    context "when reading answers", :integration do
      context "when reading the collection" do
        it "should return an empty hash, if there are no answers" do
          expect(response.normalized_answers).to eq({})
        end

        it "should return the normalized answers for a questionnaire response" do
          question2 = create(:multiple_choice_question_multiple)
          questions << question2

          answer_text = "response text value 1"
          response.answers.create(
            question: question,
            answer: ValueTypes::Text.new(" \n\r\t#{answer_text} \n\r\t"),
            question_text: question.question_text
          )

          choices = question2.metadata["multiple-choice"]["choices"][0..1].map { |choice| choice["value"] }
          answer_text2 = choices.join(", ")
          response.answers.create(
            question: question2,
            answer: ValueTypes::Text.new(" \n\r\t#{answer_text2} \n\r\t"),
            question_text: question2.question_text
          )

          expect(response.normalized_answers)
            .to eq(
              question.question_identifier => answer_text,
              question2.question_identifier => choices
            )
        end

        it "should return the normalized answers for a questionnaire response for given question types" do
          question2 = create(:typeform_question, question_type: "multiple-choice")
          questions << question2

          answer_text = "response text value 1"
          response.answers.create(
            question: question,
            answer: ValueTypes::Text.new(answer_text),
            question_text: question.question_text
          )

          answer_text2 = "response text value 2"
          response.answers.create(
            question: question2,
            answer: ValueTypes::Text.new(answer_text2),
            question_text: question2.question_text
          )

          normalized_answers = response.normalized_answers(question_types: %w[multiple-choice])
          expect(normalized_answers).to eq(question.question_identifier => answer_text2)

          expect(response.normalized_answers(question_types: %w[multiple-choice text]))
            .to eq(
              question.question_identifier => answer_text,
              question2.question_identifier => answer_text2
            )
        end
      end
    end
  end

  context "#create_profile_data!" do
    let(:property_1) { ProfileProperty.create(name: "Eine Info", description: "Irgendwas", value_type: "Text") }
    let(:property_2) { ProfileProperty.create(name: "Eine zweite Info", description: "Irgendwas", value_type: "Text") }
    let(:question) { create(:typeform_question, profile_property: property_1) }
    let(:question2) { create(:typeform_question, profile_property: property_2) }
    let(:questionnaire) { create(:questionnaire, questions: [question, question2]) }
    let(:response) { create(:questionnaire_response, questionnaire: questionnaire) }

    it "updates the users profile with all given answers" do
      response.answers.create(question: question, question_text: question.question_text, answer: ValueTypes::Text.new("Meine Antwort"))
      response.answers.create(question: question2, question_text: question2.question_text, answer: ValueTypes::Text.new("Meine andere Antwort"))

      expect(property_1).to receive(:update_profile_for).with(response.mandate, ValueTypes::Text.new("Meine Antwort"), source: "questionnaire_response-#{response.id}").once
      expect(property_2).to receive(:update_profile_for).with(response.mandate, ValueTypes::Text.new("Meine andere Antwort"), source: "questionnaire_response-#{response.id}").once

      response.create_profile_data!
    end
  end

  context ".find_user_response_by_category" do
    let(:mandate) { create(:mandate) }
    let(:other_mandate) { create(:mandate) }
    let(:category) { create(:category) }
    let(:questionnaire) { create(:questionnaire, category: category) }
    let!(:response) { create(:questionnaire_response, questionnaire: questionnaire, mandate: mandate, state: "completed") }

    it "finds a questionnaire response when one is present" do
      expect(described_class.find_user_response_by_category(category, mandate)).to eq(response)
    end

    it "returns nil when there is no questionnaire response for that mandate" do
      expect(described_class.find_user_response_by_category(category, other_mandate)).to be_nil
    end

    it "returns the most recent questionnaire response" do
      new_response = create(:questionnaire_response, questionnaire: questionnaire, mandate: mandate, state: "completed")

      expect(described_class.find_user_response_by_category(category, mandate)).to eq(new_response)
    end

    it "expects the response to be questionnaire response and contain answers" do
      expect(described_class.find_user_response_by_category(category, mandate)).to eq(response)
      expect(described_class.find_user_response_by_category(category, mandate)).to be_a(described_class)
      expect(described_class.find_user_response_by_category(category, mandate)).to respond_to(:answers)
    end

    it "does not retrieve questionnaire that are not on complete state " do
      response.update(state: "in_progress")

      expect(described_class.find_user_response_by_category(category, mandate)).to be_nil
    end
  end
end
