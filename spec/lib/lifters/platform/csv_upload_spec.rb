# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::CsvUpload do
  subject { described_class }

  let(:csv) { instance_double(ActionDispatch::Http::UploadedFile) }
  let(:csv_type) { instance_double(DocumentType) }

  let(:documentable) { n_double("documentable") }

  before do
    allow(DocumentType).to receive(:csv).with(no_args).and_return(csv_type)
  end

  it "should raise an error if the file is missing" do
    expect{
      subject.persist_file(nil, documentable)
    }.to raise_error(Platform::Errors::MissingFileParamException)
  end

  it "should create a document with the file's content if given" do
    expect(Document).to receive(:create!)
      .with(documentable: documentable, asset: csv, document_type: csv_type)
    subject.persist_file(csv, documentable)
  end

  it "should return the created document" do
    created_document = instance_double(Document)
    allow(Document).to receive(:create!)
      .with(documentable: documentable, asset: csv, document_type: csv_type)
      .and_return(created_document)
    expect(subject.persist_file(csv, documentable)).to eq(created_document)
  end
end
