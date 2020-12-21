# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/interactors/find_contract_for_instant_advice"

RSpec.describe Contracts::Interactors::FindContractForInstantAdvice do
  let(:interactor) { described_class.new(contract_repo: repo_double) }
  let(:repo_double) { double("repo") }
  let(:contract) { double("Contracts", id: 1) }

  before do
    allow(repo_double).to receive(:build_entity).and_return(contract)
  end

  it "calls repostory to retrieve contract" do
    expect(repo_double).to receive(:find_contract_for_instant_advice)

    interactor.call(contract.id)
  end

  context "when contract exists" do
    before do
      allow(repo_double).to receive(
        :find_contract_for_instant_advice
      ).with(contract.id).and_return(contract)
    end

    it "returns contract" do
      result = interactor.call(contract.id)
      expect(result).to be_kind_of Utils::Interactor::Result
      expect(result).to be_successful
      expect(result.contract.id).to eq contract.id
    end
  end

  context "when contract does not exist" do
    let(:contract_id) { 999 }

    before do
      allow(repo_double).to receive(
        :find_contract_for_instant_advice
      ).with(contract_id).and_return(nil)
    end

    it "returns an error" do
      result = interactor.call(contract_id)
      expect(result).not_to eq be_successful
    end
  end
end
