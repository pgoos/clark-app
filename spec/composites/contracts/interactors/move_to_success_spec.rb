# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/interactors/move_to_success"

RSpec.describe Contracts::Interactors::MoveToSuccess do
  let(:details_missing_state) { Contracts::Entities::Contract::AnalysisState::DETAILS_MISSING }
  let(:details_completed_state) { Contracts::Entities::Contract::AnalysisState::DETAILS_COMPLETE }
  let(:contract) do
    double("Contract", id: 1, analysis_state: details_missing_state, customer_id: 1)
  end
  let(:contract_with_invalid_state) { double("contract", id: 1, analysis_state: nil) }
  let(:contract_repo) { double("contract_repo") }

  before do
    allow(subject).to receive(:contract_repo).and_return(contract_repo)
  end

  context "when details_missing state changes to details_completed" do
    it "tries to update contract with correct state" do
      allow(contract_repo).to receive(:find_contract_with_analysis).and_return(contract)
      expect(subject.state_machine).to receive(:fire_event!)
        .with(contract.analysis_state, :customer_provides_details)
        .and_return(details_completed_state)
      expect(contract_repo)
        .to receive(:update_analysis_state!)
        .with(contract, analysis_state: details_completed_state)

      subject.call(contract.id)
    end
  end

  context "when invalid state transition happens" do
    it "raise InvalidTransition" do
      allow(contract_repo).to receive(:find_contract_with_analysis).and_return(contract_with_invalid_state)
      result = subject.call(contract_with_invalid_state.id)

      expect(result).not_to be_successful
    end
  end
end
