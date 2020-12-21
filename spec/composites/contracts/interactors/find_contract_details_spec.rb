# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/interactors/find_contract_details"

RSpec.describe Contracts::Interactors::FindContractDetails do
  let(:repo_double) { double("repo") }
  let(:contract) { build(:contract) }
  let(:mocked_find_contract_details) do
    {
      id: contract.id,
      state: contract.state,
      analysis_state: contract.analysis_state,
      customer_id: contract.customer_id,
      customer_name: contract.customer_name,
      category_ident: contract.category_ident,
      category_name: contract.category_name,
      category_tips: contract.category_tips,
      coverage_features: [],
      plan_name: contract.plan_name,
      company_ident: contract.company_ident,
      company_name: contract.company_name,
      company_logo: contract.company_logo,
      rating_score: contract.rating_score,
      rating_text: contract.rating_text,
      documents: contract.documents,
      created_at: contract.created_at,
      coverages: contract.coverages
    }
  end

  before do
    allow(subject).to receive(:contract_repo).and_return(repo_double)
    allow(repo_double).to receive(:build_entity).and_return(contract)
  end

  context "when contract exists" do
    before do
      allow(repo_double)
        .to receive(:find_contract_details).with(id: contract.id).and_return(mocked_find_contract_details)
    end

    it "returns contract" do
      result = subject.call(contract.id)
      expect(result).to be_kind_of Utils::Interactor::Result
      expect(result).to be_successful
      expect(result.contract).to be_kind_of Contracts::Entities::Contract
      expect(result.contract.id).to eq contract.id
    end

    context "when contract is details_missing" do
      it "estimated_time_to_finish_analysis is set as nil" do
        result = subject.call(contract.id)

        expect(result.contract.estimated_time_to_finish_analysis).to be_nil
      end
    end
  end

  context "when contract does not exist" do
    let(:non_existing_contract_id) { 999 }

    before do
      allow(repo_double)
        .to receive(:find_contract_details).and_return(nil)
    end

    it "returns an error" do
      result = subject.call(non_existing_contract_id)
      expect(result).not_to eq be_successful
    end
  end

  context "when contract is under_analysis" do
    let(:document) do
      double(
        "document",
        document_type: Contracts::Entities::Document::CustomerUploaded,
        created_at: Time.current,
        visible_to_customer: true
      )
    end
    let :mock_contract_details do
      mocked_find_contract_details.merge(
        documents: [document],
        analysis_state: Contracts::Entities::Contract::AnalysisState::UNDER_ANALYSIS
      )
    end

    context "when customer has uploaded document on weekday" do
      let(:weekday_time) { Time.strptime("2020-01-02T00:00:00", "%Y-%m-%d") }

      before do
        Timecop.freeze(weekday_time)
        allow(repo_double)
          .to receive(:find_contract_details).with(id: contract.id).and_return(mock_contract_details)
      end

      after do
        Timecop.return
      end

      it "estimated_time is set as after 24 hours" do
        estimated_time = subject.call(contract.id).contract.estimated_time_to_finish_analysis

        expect(estimated_time).to eq(weekday_time + 24.hours)
      end
    end

    context "when customer has uploaded document on weekend" do
      let(:weekend) { Time.strptime("2020-01-03T00:00:00", "%Y-%m-%d") }

      before do
        Timecop.freeze(weekend)
        allow(repo_double)
          .to receive(:find_contract_details).with(id: contract.id).and_return(mock_contract_details)
      end

      after do
        Timecop.return
      end

      it "estimated_time is set as after 76 hours" do
        estimated_time = subject.call(contract.id).contract.estimated_time_to_finish_analysis

        expect(estimated_time).to eq(weekend + 76.hours)
      end
    end

    context "when customer has uploaded document on weekday and document_type was changed" do
      let(:weekday_time) { Time.strptime("2020-01-02T00:00:00", "%Y-%m-%d") }

      let(:contract_document) do
        double(
          "document",
          document_type: DocumentType.contract_information,
          created_at: Time.current,
          visible_to_customer: true
        )
      end

      let :mock_contract_details do
        mocked_find_contract_details.merge(
          documents: [contract_document],
          analysis_state: Contracts::Entities::Contract::AnalysisState::UNDER_ANALYSIS
        )
      end

      before do
        Timecop.freeze(weekday_time)
        allow(repo_double)
          .to receive(:find_contract_details).with(id: contract.id).and_return(mock_contract_details)
      end

      after do
        Timecop.return
      end

      it "estimated_time is set as after 24 hours" do
        estimated_time = subject.call(contract.id).contract.estimated_time_to_finish_analysis

        expect(estimated_time).to eq(weekday_time + 24.hours)
      end
    end

    context "when uploaded document is not visible for customer" do
      let(:weekday_time) { Time.strptime("2020-01-02T00:00:00", "%Y-%m-%d") }

      let(:contract_document) do
        double(
          "document",
          document_type: DocumentType.contract_information,
          created_at: Time.current,
          visible_to_customer: false
        )
      end

      let :mock_contract_details do
        mocked_find_contract_details.merge(
          documents: [contract_document],
          analysis_state: Contracts::Entities::Contract::AnalysisState::UNDER_ANALYSIS
        )
      end

      before do
        Timecop.freeze(weekday_time)
        allow(repo_double)
          .to receive(:find_contract_details).with(id: contract.id).and_return(mock_contract_details)
      end

      after do
        Timecop.return
      end

      it "estimated_time is nil" do
        estimated_time = subject.call(contract.id).contract.estimated_time_to_finish_analysis

        expect(estimated_time).to be_nil
      end
    end
  end
end
