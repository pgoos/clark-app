# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/repositories/contract_repository"

RSpec.describe Contracts::Repositories::DocumentRepository, :integration do
  subject { described_class.new }

  let(:customer) { create :customer }
  let(:contract) { create :product, mandate_id: customer.id }

  describe "#upload_documents" do
    let(:file) do
      {
        filename: "blank_1.pdf",
        type: "",
        tempfile: fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
      }
    end

    context "when file is passed in" do
      it "triggers InquiryDocumentsRepository with parameters" do
        expect_any_instance_of(Domain::ContractOverview::InquiryDocumentsRepository)
          .to receive(:create)
          .with(contract, [file, file])
          .and_call_original

        result =
          subject.upload_documents(
            contract: contract,
            documents: [file, file]
          )

        expect(result).to be_a(Array)
        expect(result.first).to be_a(::Contracts::Entities::Document)
        expect(result.count).to eq(2)
      end
    end
  end

  describe "#find_by_contract" do
    let!(:contract) { create(:contract, :with_customer_uploaded_document, customer_id: customer.id) }

    context "when called with visible_to_customer: true" do
      it "return customer document" do
        docs = subject.find_by_contract(
          contract_id: contract.id,
          only_visible_to_customer: true,
          customer_state: "self_service"
        )
        expect(docs.count).to eq(1)
      end
    end

    context "when called with visible_to_customer: false" do
      let!(:document_not_visible_to_customer) do
        create(:document, documentable_id: contract.id, documentable_type: ::Product.name)
      end

      it "return all documents for contract" do
        docs = subject.find_by_contract(contract_id: contract.id, only_visible_to_customer: false)
        expect(docs.count).to eq(2)
      end
    end
  end
end
