# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/constituents/shared_contracts/repositories/shared_contract_repository"

RSpec.describe Contracts::Constituents::SharedContracts::Repositories::SharedContractRepository, :integration do
  let(:repo) { described_class.new }
  let(:admin) { create(:super_admin) }

  before do
    allow(Features).to receive(:active?).and_call_original
    allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(true)
  end

  describe "#count_shared_contracts_under_analysis" do
    before do
      create(:product, :shared_contract, analysis_state: :under_analysis)
      create(:product, analysis_state: :under_analysis)
    end

    it "counts only shared contracts" do
      expect(Product.unscoped.count).to be(2)
      result = repo.count_shared_contracts_under_analysis(admin: admin)
      expect(result).to be(1)
    end

    context "when admin can't view revoked mandates" do
      before do
        revoked_mandate = create(:mandate, :revoked)
        create(:product, :shared_contract, analysis_state: :under_analysis, mandate: revoked_mandate)
      end

      it "counts only contract owned by non revoked mandates" do
        expect(Product.unscoped.count).to be(3)
        result = repo.count_shared_contracts_under_analysis(admin: admin)
        expect(result).to be(1)
      end
    end

    context "when admin can view revoked mandates" do
      before do
        allow(admin).to receive(:can_view_revoked_mandates?).and_return(true)
        revoked_mandate = create(:mandate, :revoked)
        create(:product, :shared_contract, analysis_state: :under_analysis, mandate: revoked_mandate)
      end

      it "counts only contract owned by non revoked mandates" do
        expect(Product.unscoped.count).to be(3)
        result = repo.count_shared_contracts_under_analysis(admin: admin)
        expect(result).to be(2)
      end
    end
  end

  describe "#shared_contracts_under_analysis" do
    before do
      create(:product, analysis_state: :under_analysis)
    end

    it "returns only shared contracts" do
      shared_contract = create(:product, :shared_contract, analysis_state: :under_analysis)
      expect(Product.unscoped.count).to be(2)

      results = repo.shared_contracts_under_analysis(per: 1, page: 1, admin: admin)
      expect(results.size).to be(1)

      result = results.first
      %i[
        id
        plan_name
        company_name
      ].each do |attr|
        expect(result.public_send(attr)).to eq(shared_contract.public_send(attr))
      end
    end

    context "when admin can't view revoked mandates" do
      before do
        revoked_mandate = create(:mandate, :revoked)
        create(:product, :shared_contract, analysis_state: :under_analysis, mandate: revoked_mandate)
      end

      it "returns only contract owned by non revoked mandates" do
        shared_contract = create(:product, :shared_contract, analysis_state: :under_analysis)
        expect(Product.unscoped.count).to be(3)

        results = repo.shared_contracts_under_analysis(per: 1, page: 1, admin: admin)
        expect(results.size).to be(1)

        result = results.first
        %i[
          id
          plan_name
          company_name
        ].each do |attr|
          expect(result.public_send(attr)).to eq(shared_contract.public_send(attr))
        end
      end
    end

    context "when admin can view revoked mandates" do
      before do
        allow(admin).to receive(:can_view_revoked_mandates?).and_return(true)
      end

      it "counts only contract owned by non revoked mandates" do
        revoked_mandate = create(:mandate, :revoked)
        shared_contract = create(:product, :shared_contract, analysis_state: :under_analysis, mandate: revoked_mandate)
        expect(Product.unscoped.count).to be(2)

        results = repo.shared_contracts_under_analysis(per: 1, page: 1, admin: admin)
        expect(results.size).to be(1)

        result = results.first
        %i[
          id
          plan_name
          company_name
        ].each do |attr|
          expect(result.public_send(attr)).to eq(shared_contract.public_send(attr))
        end
      end
    end
  end
end
