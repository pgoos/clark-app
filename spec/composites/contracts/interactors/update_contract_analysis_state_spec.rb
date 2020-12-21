# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Interactors::UpdateContractAnalysisState do
  describe "#call" do
    let(:double_repository) { instance_double(Contracts::Repositories::ContractRepository) }
    let(:state_machine) { class_double(Contracts::StateMachines::ContractAnalysisStateMachine) }
    let(:interactor) { described_class.new(contract_repo: double_repository, state_machine: state_machine) }

    context "when there is a contract" do
      let(:analysis_state_event) { :request_analysis }
      let(:contract) { double(id: 1, analysis_state: :request_analysis) }
      let(:new_analysis_state) { :under_analysis }

      it "retrieves contract and updates its analysis_state" do
        expect(state_machine)
          .to receive(:fire_event!).with(contract.analysis_state, analysis_state_event).and_return(new_analysis_state)
        expect(double_repository)
          .to receive(:find_contract_with_analysis).with(contract_id: contract.id).and_return(contract)
        expect(double_repository)
          .to receive(:update_analysis_state!).with(contract, analysis_state: new_analysis_state)

        result = interactor.call(contract.id, analysis_state_event)
        expect(result.success?).to be true
      end
    end

    context "when there isn't a contract" do
      let(:contract) { double(id: 1) }
      let(:analysis_state_event) { :request_analysis }

      it "returns an error" do
        allow(double_repository).to receive(:find_contract_with_analysis).and_return(nil)
        expect(state_machine).not_to receive(:fire_event!)
        expect(double_repository).not_to receive(:update_analysis_state!)

        result = interactor.call(contract.id, analysis_state_event)
        expect(result.success?).to be false
        expect(result.errors).to include("Contract not found")
      end
    end
  end
end
