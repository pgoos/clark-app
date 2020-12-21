# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::FileUpload do
  subject { described_class }

  let(:document) { instance_double(ActionDispatch::Http::UploadedFile) }
  let(:document_type) { instance_double(DocumentType) }

  let(:documentable) { n_double("documentable") }

  it "should raise an error if the file is missing" do
    expect {
      subject.persist_file(nil, documentable, document_type)
    }.to raise_error(Platform::Errors::MissingFileParamException)
  end

  it "should create a document with the file's content if given" do
    expect(Document).to receive(:create!)
      .with(documentable: documentable, asset: document, document_type: document_type)
    subject.persist_file(document, documentable, document_type)
  end

  it "should return the created document" do
    created_document = instance_double(Document)
    allow(Document).to receive(:create!)
      .with(documentable: documentable, asset: document, document_type: document_type)
      .and_return(created_document)
    expect(subject.persist_file(document, documentable, document_type)).to eq(created_document)
  end
end
