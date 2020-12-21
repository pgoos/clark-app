# frozen_string_literal: true

require "rails_helper"

require "composites/customer/constituents/surveys/interactors/close_nps_cycle"
require "composites/customer/constituents/surveys/repositories/nps_cycle_repository"

RSpec.describe Customer::Constituents::Surveys::Interactors::CloseNPSCycle do
  let(:nps_cycle_repository)    { instance_double(Customer::Constituents::Surveys::Repositories::NPSCycleRepository) }
  let(:state_machine)           { class_double(Customer::Constituents::Surveys::StateMachines::NPSCycleState) }
  let(:interactor) do
    described_class.new(nps_cycle_repo: nps_cycle_repository, nps_cycle_state_machine: state_machine)
  end

  let(:nps_cycle) { create(:nps_cycle, :closing, maximum_score: 10) }
  let(:nps_cycle_entity) do
    OpenStruct.new({ id: nps_cycle.id, state: nps_cycle.state, closed?: nps_cycle.state == "CLOSED" })
  end

  before do
    allow(nps_cycle_repository).to receive(:find_by).with(cycle_id: nps_cycle.id).and_return(nps_cycle_entity)
  end

  describe "#call" do
    context "when valid" do
      context "when cycle is ready to be closed" do
        it "calls state machine & repository and receives successful result" do
          expect(state_machine).to        receive(:fire_event!).with("CLOSING", :closed).and_return("CLOSED")
          expect(nps_cycle_repository).to receive(:update_cycle_state!).with(nps_cycle.id, "CLOSED")

          result = interactor.call(nps_cycle.id)
          expect(result.ok?).to be(true)
        end
      end

      context "when cycle is already closed" do
        let(:nps_cycle) { create(:nps_cycle, :closed, maximum_score: 10) }

        it "receives successful result" do
          result = interactor.call(nps_cycle.id)
          expect(result.ok?).to be(true)
        end
      end
    end

    context "when exception occurs" do
      shared_examples "handles exception" do
        let(:error_msg) { "Everything is broken!" }

        it "catches the error and returns valid error message" do
          result = interactor.call(nps_cycle.id)
          expect(result.ok?).to be(false)
          result.on_failure { |error| expect(error.message).to eq(error_msg) }
        end
      end

      context "when state machine error occurs" do
        before do
          allow(state_machine).to receive(:fire_event!)
            .with("CLOSING", :closed)
            .and_raise(Utils::StateMachine::InvalidTransition, error_msg)
        end

        it_behaves_like "handles exception"
      end

      context "when repository error occurs" do
        before do
          allow(state_machine).to receive(:fire_event!).with("CLOSING", :closed).and_return("CLOSED")
          allow(nps_cycle_repository).to receive(:update_cycle_state!)
            .with(nps_cycle.id, "CLOSED")
            .and_raise(Utils::Repository::Error, error_msg)
        end

        it_behaves_like "handles exception"
      end
    end
  end
end
