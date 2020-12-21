# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rake fix_data:questionnaire_responses_with_multiple_opportunities", type: :task do
  let(:source) { create :questionnaire_response }

  before do
    allow_any_instance_of(Logger).to receive(:warn)
    allow_any_instance_of(Logger).to receive(:info)
  end

  context "when multiple opportunities share the same source" do
    context "when source is questionnaire response" do
      context "without active opportunities" do
        it "deletes \"lost\" opportunities" do
          create_list :shallow_opportunity, 2, :lost, source: source
          task.invoke
          expect(Opportunity.lost.count).to eq 1
        end
      end

      context "with active opportunities" do
        it "deletes all \"lost\" opportunities" do
          create_list :shallow_opportunity, 2, :lost, source: source
          create :shallow_opportunity, :offer_phase, source: source
          task.invoke
          expect(Opportunity.lost.count).to eq 0
          expect(Opportunity.offer_phase.count).to eq 1
        end
      end

      it "shows warning if there are more than one active opportunity" do
        create_list :shallow_opportunity, 2, :offer_phase, source: source
        expect_any_instance_of(Logger).to receive(:warn)
        task.invoke
        expect(Opportunity.offer_phase.count).to eq 2
      end
    end

    context "when source is not questionnaire response" do
      it "does nothing" do
        create_list :shallow_opportunity, 2, :lost
        create :shallow_opportunity, :offer_phase
        task.invoke
        expect(Opportunity.lost.count).to eq 2
        expect(Opportunity.offer_phase.count).to eq 1
      end
    end
  end

  context "when multiple opportunities do not share the same questionnaire response" do
    it "does nothing" do
      create :shallow_opportunity, :lost, source: source
      create :shallow_opportunity, :lost, source: create(:questionnaire_response)
      task.invoke
      expect(Opportunity.lost.count).to eq 2
    end
  end
end
