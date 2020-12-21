# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::Matrix do
  context "when rules are matched" do
    let(:response) { n_instance_double(Questionnaire::Response, "response") }
    let(:rules_repository) { ::OfferGeneration.rules_repository }
    let(:matching_rule1) { n_instance_double(OfferRule, "matching_rule1") }
    let(:matching_rule2) { n_instance_double(OfferRule, "matching_rule2") }
    let(:question_types) { [Domain::Questionnaires::MultipleChoice.question_type] }
    let(:quest_ident) { "quest_ident1" }
    let(:answer_value) { "answer value 1" }
    let(:ignore) { "ignore" }
    let(:stop_automation) { "break" }

    before do
      allow(response).to receive(:extract_normalized_answer).with(quest_ident).and_return(answer_value)
      allow(response).to receive(:normalized_answers).and_return(quest_ident => answer_value)
    end

    it "should yield, if a match is found" do
      allow(rules_repository)
        .to receive(:find_active_rules_for)
        .with(response: response, question_types: question_types)
        .and_return([matching_rule1])
      allow(matching_rule1).to receive(:answer_values).and_return(quest_ident => answer_value)

      expect { |b| described_class.with_matching_rule(response: response, &b) }.to yield_with_args(matching_rule1)
    end

    it "should not yield, if the rule is ambiguous" do
      allow(rules_repository)
        .to receive(:find_active_rules_for)
        .with(response: response, question_types: question_types)
        .and_return([matching_rule1, matching_rule2])
      allow(matching_rule1).to receive(:answer_values).and_return(quest_ident => ignore)
      allow(matching_rule2).to receive(:answer_values).and_return(quest_ident => ignore)

      expect { |b| described_class.with_matching_rule(response: response, &b) }.not_to yield_control
    end

    it "should drop a rule, if the rule says so" do
      allow(rules_repository)
        .to receive(:find_active_rules_for)
        .with(response: response, question_types: question_types)
        .and_return([matching_rule1, matching_rule2])

      allow(matching_rule1).to receive(:answer_values).and_return(quest_ident => answer_value)
      allow(matching_rule2).to receive(:answer_values).and_return(quest_ident => stop_automation)

      expect { |b| described_class.with_matching_rule(response: response, &b) }.to yield_with_args(matching_rule1)
    end

    it "matches only an exact questionnaire responses" do
      allow(rules_repository)
        .to receive(:find_active_rules_for)
        .with(response: response, question_types: question_types)
        .and_return([matching_rule1, matching_rule2])

      allow(matching_rule1).to receive(:answer_values).and_return(quest_ident => answer_value)
      allow(matching_rule2).to receive(:answer_values).and_return(quest_ident => answer_value, "other_ident" => answer_value)

      expect { |b| described_class.with_matching_rule(response: response, &b) }.to yield_with_args(matching_rule1)
    end

    it "rejects ignore answer values" do
      allow(rules_repository)
        .to receive(:find_active_rules_for)
        .with(response: response, question_types: question_types)
        .and_return([matching_rule1, matching_rule2])

      allow(matching_rule1).to receive(:answer_values).and_return(quest_ident => answer_value, "other_ident" => ignore)
      allow(matching_rule2).to \
        receive(:answer_values).and_return(quest_ident => answer_value, "other_ident" => answer_value)

      expect { |b| described_class.with_matching_rule(response: response, &b) }.to yield_with_args(matching_rule1)
    end

    it "rejects break answer values" do
      allow(rules_repository)
        .to receive(:find_active_rules_for)
        .with(response: response, question_types: question_types)
        .and_return([matching_rule1, matching_rule2])

      allow(response).to receive(:extract_normalized_answer).with(quest_ident).and_return("")
      allow(matching_rule1).to receive(:answer_values).and_return(quest_ident => answer_value, "other_ident" => ignore)
      allow(matching_rule2).to \
        receive(:answer_values).and_return(quest_ident => "break", "other_ident" => answer_value)

      expect { |b| described_class.with_matching_rule(response: response, &b) }.to yield_with_args(matching_rule1)
    end
  end
end
