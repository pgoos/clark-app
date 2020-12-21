# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Constituents::SharedContracts::Interactors::FindSharedContractsUnderAnalysis do
  let(:shared_contract_repository) do
    instance_double("Contracts::Constituents::SharedContracts::SharedContractRepository")
  end

  let(:interactor) { described_class.new(shared_contract_repository: shared_contract_repository) }

  context "no shared contracts under analysis" do
    before do
      allow(shared_contract_repository).to receive(:shared_contracts_under_analysis).and_return([])
      allow(shared_contract_repository).to receive(:count_shared_contracts_under_analysis).and_return(0)
    end

    it "returns an empty contracts array and zero as total" do
      result = interactor.call
      result.on_success do |contracts:, total_shared_contracts:|
        expect(contracts).to be_empty
        expect(total_shared_contracts).to be(0)
      end
    end
  end

  context "contracts under analysis exist" do
    let(:dummy_contracts) { Array.new(2) { double("Contract") } }
    let(:dummy_total) { dummy_contracts.length }

    before do
      allow(shared_contract_repository).to receive(:shared_contracts_under_analysis).and_return(dummy_contracts)
      allow(shared_contract_repository).to receive(:count_shared_contracts_under_analysis).and_return(dummy_total)
    end

    it "returns contracts" do
      result = interactor.call
      result.on_success do |contracts:, total_shared_contracts:|
        expect(contracts).to match(dummy_contracts)
        expect(total_shared_contracts).to be(dummy_total)
      end
    end
  end
end
