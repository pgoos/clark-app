# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::InquiryDocumentsRepository, :integration do
  subject(:repo) { described_class.new }

  it do
    expect(described_class::DOCUMENTS_AVAILABLE_TO_CUSTOMER).to eq %w[CUSTOMER]
  end

  describe "#all" do
    it "filters documents out according available to customer document types" do
      stub_const("#{described_class}::DOCUMENTS_AVAILABLE_TO_CUSTOMER", %w[DT1 DT3])

      document_type1 = create(:document_type, key: "DT1")
      document1 = build_stubbed(:document, document_type: document_type1)

      document_type2 = create(:document_type, key: "DT2")
      document2 = build_stubbed(:document, document_type: document_type2)
      document3 = build_stubbed(:document)

      documents = [
        document1,
        document2,
        document3
      ]

      inquiry = build_stubbed :inquiry, documents: documents

      expect(repo.all(inquiry)).to match_array [document1]
    end
  end

  describe "#create" do
    it "inserts new entries in documents table" do
      inquiry = create :inquiry
      files = [
        {
          filename: "blank1.pdf",
          type: "",
          tempfile: fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
        },
        {
          filename: "blank2.pdf",
          type: "",
          tempfile: fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
        }
      ]
      documents = repo.create(inquiry, files)

      expect(documents.size).to eq 2
      expect(inquiry.documents.reload.to_a).to match_array documents
      expect(documents[0].document_type_id).to eq DocumentType.customer_upload.id
      expect(documents[1].document_type_id).to eq DocumentType.customer_upload.id
    end

    context "with images" do
      it "generates one pdf from images" do
        inquiry = create :inquiry
        files = [
          {
            filename: "blank1.png",
            type: "image/png",
            tempfile: fixture_file_upload(Rails.root.join("spec", "fixtures", "empty_signature.png"))
          },
          {
            filename: "blank2.png",
            type: "image/png",
            tempfile: fixture_file_upload(Rails.root.join("spec", "fixtures", "empty_signature.png"))
          }
        ]
        documents = repo.create(inquiry, files)

        expect(documents.size).to eq 1
        expect(inquiry.documents.reload.to_a).to match_array documents
        expect(documents[0].document_type_id).to eq DocumentType.customer_upload.id
        expect(documents[0].content_type).to eq "application/pdf"
      end
    end
  end
end
