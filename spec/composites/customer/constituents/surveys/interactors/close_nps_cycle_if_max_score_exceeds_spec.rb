# frozen_string_literal: true

require "rails_helper"

require "composites/customer/constituents/surveys/interactors/close_nps_cycle_if_max_score_exceeds"
require "composites/customer/constituents/surveys/repositories/nps_cycle_repository"

RSpec.describe Customer::Constituents::Surveys::Interactors::CloseNPSCycleIfMaxScoreExceeds do
  let(:job)                   { class_double(Customer::Constituents::Surveys::Jobs::CloseNPSCycleJob) }
  let(:nps_cycle_repository)  { instance_double(Customer::Constituents::Surveys::Repositories::NPSCycleRepository) }
  let(:state_machine)         { class_double(Customer::Constituents::Surveys::StateMachines::NPSCycleState) }
  let(:interactor) do
    described_class.new(close_nps_cycle_job: job,
                        nps_cycle_repo: nps_cycle_repository,
                        nps_cycle_state_machine: state_machine)
  end

  let(:nps_cycle)         { create(:nps_cycle, :open, maximum_score: 10) }
  let(:nps_cycle_entity)  { OpenStruct.new({ id: nps_cycle.id, state: nps_cycle.state, maximum_score: 10 }) }

  describe "#call" do
    context "when valid" do
      context "when the cycle is ready to be closed" do
        it "calls repository & state machine, then triggers delayed job and returns successful result" do
          expect(nps_cycle_repository).to receive(:open_cycle).and_return(nps_cycle_entity)
          expect(nps_cycle_repository).to receive(:amount_of_rated_nps_interactions).with(nps_cycle.id).and_return(10)
          expect(state_machine).to        receive(:fire_event!).with("OPEN", :closing).and_return("CLOSING")
          expect(nps_cycle_repository).to receive(:update_cycle_state!).with(nps_cycle.id, "CLOSING")
          expect(job).to                  receive_message_chain(:set, :perform_later)

          result = interactor.call
          expect(result.ok?).to be(true)
        end
      end

      context "where there is no opened cycle" do
        it "calls repository and returns successful result" do
          expect(nps_cycle_repository).to receive(:open_cycle).and_return(nil)

          result = interactor.call
          expect(result.ok?).to be(true)
        end
      end

      context "when summary score is lower than maximum score" do
        it "calls repository and returns successful result" do
          expect(nps_cycle_repository).to receive(:open_cycle).and_return(nps_cycle_entity)
          expect(nps_cycle_repository).to receive(:amount_of_rated_nps_interactions).with(nps_cycle.id).and_return(9)

          result = interactor.call
          expect(result.ok?).to be(true)
        end
      end
    end

    context "when exception occurs" do
      shared_examples "handles exception" do
        let(:error_msg) { "Everything is broken!" }

        it "catches the error, logs it and returns successful result" do
          expect(Rails.logger).to receive(:error).with(exception)

          result = interactor.call
          expect(result.ok?).to be(true)
        end
      end

      context "when state machine error occurs" do
        let(:exception) { Utils::StateMachine::InvalidTransition }

        before do
          allow(nps_cycle_repository).to receive(:open_cycle).and_return(nps_cycle_entity)
          allow(nps_cycle_repository).to receive(:amount_of_rated_nps_interactions).with(nps_cycle.id).and_return(15)
          allow(state_machine).to receive(:fire_event!).with("OPEN", :closing).and_raise(exception, error_msg)
        end

        it_behaves_like "handles exception"
      end

      context "when repository error occurs" do
        let(:exception) { Utils::Repository::Error }

        before do
          allow(nps_cycle_repository).to receive(:open_cycle).and_raise(exception, error_msg)
        end

        it_behaves_like "handles exception"
      end
    end
  end
end
