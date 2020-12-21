# frozen_string_literal: true

require "spec_helper"
require "composites/contracts/interactors/add_contracts"
require "composites/contracts/params"

RSpec.describe Contracts::Interactors::AddContracts do
  let(:contract_repo) { double :repo, add_contracts!: [contract] }
  let(:contract) { double :contract }
  let(:customer_id) { 1 }
  let(:contract_params) do
    [
      Contracts::Params::NewContract.new(
        category_ident: "FOO",
        company_ident: "BAR",
        shared: true
      )
    ]
  end

  before { allow(subject).to receive(:contract_repo).and_return(contract_repo) }

  context "when contracts are created successfully" do
    it "returns result object with success true" do
      expect(contract_repo).to receive(:add_contracts!).with(customer_id, contract_params)
      result = subject.call(customer_id, contract_params)
      expect(result).to be_successful
    end

    it "exposes created contracts" do
      result = subject.call(customer_id, contract_params)
      expect(result.contracts).to eq([contract])
    end
  end

  context "when validation error raised" do
    before do
      allow(contract_repo).to receive(:add_contracts!).and_raise(ActiveRecord::ActiveRecordError)
      stub_const("#{contract_repo.class}::Error", StandardError)
    end

    it "returns result object with success false" do
      expect(subject).to receive(:error!).and_call_original
      result = subject.call(customer_id, contract_params)
      expect(result).not_to be_successful
    end
  end
end
