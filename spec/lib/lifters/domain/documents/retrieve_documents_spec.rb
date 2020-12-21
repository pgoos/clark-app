# frozen_string_literal: true

require "spec_helper"
require "ostruct"

require "structs/document"
require "repositories/documents_repository"
require "lifters/domain/documents/retrieve_documents"

RSpec.describe Domain::Documents::RetrieveDocuments do
  let(:repository) { class_double("DocumentsRepository") }
  let(:service) { described_class.new(repository) }
  let(:documents_request) do
    OpenStruct.new(
      document_owner_id: 10,
      document_owner_type: "FakeType",
      document_type: "CUSTOMER",
    )
  end

  it "calls the repository" do
    expect(repository).to receive(:find_by_owner_and_type).with(
      documents_request.document_owner_id,
      documents_request.document_owner_type,
      documents_request.document_type,
    )

    service.call(documents_request)
  end
end
