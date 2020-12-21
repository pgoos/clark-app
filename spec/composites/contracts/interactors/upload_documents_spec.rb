# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/interactors/find_contract_details"

RSpec.describe Contracts::Interactors::UploadDocuments do
  let(:details_missing_state) { Contracts::Entities::Contract::AnalysisState::DETAILS_MISSING }

  let(:contract) do
    double("Contract", id: 1, analysis_state: details_missing_state, customer_id: 1)
  end

  let(:uploaded_document) do
    build(
      :document,
      documentable_id: contract.id,
      documentable_type: ::Product.name
    )
  end

  let(:file) do
    {
      filename: "blank_1.pdf",
      type: "",
      tempfile: fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
    }
  end

  before do
    allow_any_instance_of(Contracts::Repositories::ContractRepository)
      .to receive(:find_contract_with_analysis).with(contract_id: contract.id).and_return(contract)

    allow(contract).to receive(:details_missing?).and_return(true)
  end

  context "uploading documents" do
    it "triggers upload_documents with parameters" do
      expect_any_instance_of(Contracts::Repositories::DocumentRepository)
        .to receive(:upload_documents)
        .with(
          contract: contract,
          documents: [file, file, file]
        )

      subject.call(
        contract_id: contract.id,
        documents: [file, file, file],
        customer_id: contract.customer_id
      )
    end
  end

  context "analisys state transition" do
    before do
      allow_any_instance_of(Contracts::Repositories::DocumentRepository)
        .to receive(:upload_documents)
        .with(contract: contract, documents: [file, file, file])
        .and_return([uploaded_document])
    end

    it "triggers request_analysis! with parameters" do
      expect_any_instance_of(described_class)
        .to receive(:request_analysis!)
        .with(contract)

      subject.call(
        contract_id: contract.id,
        documents: [file, file, file],
        customer_id: contract.customer_id
      )
    end
  end
end
