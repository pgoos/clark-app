# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/interactors/find_contracts_under_analysis"

RSpec.describe Contracts::Interactors::FindContractsUnderAnalysis do
  let(:contract) { build(:contract, :under_analysis) }
  let(:repo_double) { double("repo") }

  before { allow(subject).to receive(:contract_repo).and_return(repo_double) }

  context "no contracts under analysis" do
    before do
      allow(repo_double).to receive(:under_analysis).and_return(nil)
      allow(repo_double).to receive(:under_analysis_count).and_return(0)
      allow(repo_double).to receive(:under_analysis_documents_count).and_return(0)
    end

    it "returns contracts" do
      result = subject.call
      expect(result).not_to be_successful
      expect(result.contracts).to be_nil
    end
  end

  context "contracts under analysis exist" do
    before do
      allow(repo_double).to receive(:under_analysis).and_return([contract])
      allow(repo_double).to receive(:under_analysis_count).and_return(1)
      allow(repo_double).to receive(:under_analysis_documents_count).and_return(1)
    end

    it "returns contracts" do
      result = subject.call
      expect(result).to be_successful
      expect(result.contracts).not_to be_nil
      expect(result.total_count).to eq 1
      expect(result.documents_count).to eq 1
    end
  end
end
