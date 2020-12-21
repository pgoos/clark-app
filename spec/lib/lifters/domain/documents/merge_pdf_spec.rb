# frozen_string_literal: true

require "spec_helper"
require "combine_pdf"
require "ostruct"

require "structs/document"
require "repositories/documents_repository"
require "lifters/domain/documents/merge_pdf"

RSpec.describe Domain::Documents::MergePDF do
  let(:repository) { class_double("DocumentsRepository") }
  let(:service) { described_class.new(repository) }
  let(:merge_request) do
    OpenStruct.new(
      document_ids: document_ids,
      document_owner_id: 10,
      document_owner_type: "InquiryCategory"
    )
  end
  let(:documents) do
    Array.new(3) do |n|
      Structs::Document.new(id: n, asset: File.open("spec/support/assets/file-#{n}.pdf"))
    end
  end
  let(:document_ids) { documents.map(&:id) }
  let(:tmp_file) { Tempfile.new(["fake", ".pdf"]) }

  before do
    allow(Tempfile).to receive(:new).and_return(tmp_file)
  end

  it "calls the repository" do
    expect(repository).to receive(:documents_by).with(
      id: merge_request.document_ids,
      documentable_id: merge_request.document_owner_id,
      documentable_type: merge_request.document_owner_type,
    ).and_return(documents)

    expect(repository).to receive(:save_customer_uploaded_file!) do |doc|
      expect(doc.documentable_id).to be(merge_request.document_owner_id)
      expect(doc.documentable_type).to eq(merge_request.document_owner_type)
      expect(doc.asset).to be(tmp_file)
    end

    expect(repository).to receive(:destroy_by).with(
      id: document_ids,
      documentable_id: merge_request.document_owner_id,
      documentable_type: merge_request.document_owner_type
    )

    service.call(merge_request)
  end

  it "merges according to the order" do
    allow(repository).to receive(:documents_by).and_return(documents)
    allow(repository).to receive(:save_customer_uploaded_file!)
    allow(repository).to receive(:destroy_by)

    merge_request.document_ids = document_ids.shuffle

    merge_request.document_ids.each do |id|
      doc = documents.find { |d| d.id == id }
      expect(CombinePDF).to receive(:parse).with(doc.asset.read).ordered.and_call_original

      doc.asset.rewind
    end

    service.call(merge_request)
  end

  context "when receive less than two document_ids" do
    let(:documents) { [] }

    it "raises an exception" do
      expect {
        service.call(merge_request)
      }.to raise_error(ArgumentError, "documents_ids must be at least 2")
    end
  end
end
