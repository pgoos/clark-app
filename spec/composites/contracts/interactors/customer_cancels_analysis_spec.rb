# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/interactors/customer_cancels_analysis"

RSpec.describe Contracts::Interactors::CustomerCancelsAnalysis do
  let(:details_missing_state) { Contracts::Entities::Contract::AnalysisState::DETAILS_MISSING }
  let(:customer_canceled_analysis_state) { Contracts::Entities::Contract::AnalysisState::CUSTOMER_CANCELED_ANALYSIS }
  let(:customer) { create(:customer, :self_service) }

  let(:contract) do
    double("Contract", id: 1, analysis_state: details_missing_state, customer_id: customer.id)
  end

  let(:contract_repo) { double("contract_repo") }
  let(:customer_without_contract) { create(:customer, :self_service) }
  let(:other_customer) { create(:customer, :self_service) }

  before do
    allow(subject).to receive(:contract_repo).and_return(contract_repo)
  end

  context "when there is a contract" do
    it "updates contract with customer_canceled_analysis state" do
      allow(contract_repo).to receive(:find_contract_with_analysis).and_return(contract)
      expect(subject.state_machine).to receive(:fire_event!)
        .with(contract.analysis_state, :customer_cancels_analysis)
        .and_return(customer_canceled_analysis_state)
      expect(contract_repo)
        .to receive(:update_analysis_state!)
        .with(contract, analysis_state: customer_canceled_analysis_state)

      subject.call(customer.id, contract.id)
    end
  end

  context "when there is no contract" do
    it "returns a not found error in the result" do
      allow(contract_repo).to receive(:find_contract_with_analysis).and_return(nil)

      result = subject.call(customer.id, 2)
      expect(result.errors).to include("not found")
    end
  end

  context "when customer does not own the contract" do
    it "returns a not found error in the result" do
      allow(contract_repo).to receive(:find_contract_with_analysis).and_return(contract)

      result = subject.call(other_customer.id, contract.id)
      expect(result.errors).to include("not found")
    end
  end
end
