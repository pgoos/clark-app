# frozen_string_literal: true

RSpec.shared_examples "a documentable" do
  let(:instance_name) { ActiveModel::Naming.singular(described_class) }
  let(:instance) { try(:shared_example_model) || create(instance_name) }
  let(:document_type) { create(:document_type) }
  let(:sample_asset) { Rack::Test::UploadedFile.new(Core::Fixtures.fake_signature_file_path) }

  it "should know, if a doc of a type is attached" do
    instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
    expect(instance.document?(document_type)).to eq(true)
  end

  it "should know, if a doc of a type is not available" do
    expect(instance.document?(document_type)).to eq(false)
  end

  describe "can return the latest document of a given type" do
    it "returns nil, if the document type is not present" do
      expect(instance.latest_document_by_type(document_type)).to be_nil
    end

    it "returns a document, if there is one present" do
      document = instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
      expect(instance.latest_document_by_type(document_type)).to eq(document)
    end

    it "returns the latest document, if there are documents" do
      instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
      document = instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
      expect(instance.latest_document_by_type(document_type)).to eq(document)
    end

    it "returns the document of the right document type" do
      document = instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
      instance.documents.create(document_type_id: create(:document_type).id, asset: sample_asset)
      expect(instance.latest_document_by_type(document_type)).to eq(document)
    end
  end

  describe "can return all documents of a given type" do
    it "returns [], if the document type is not present" do
      expect(instance.documents_by_type(document_type)).to eq([])
    end

    it "returns an array with a document, if there is one present" do
      document = instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
      expect(instance.documents_by_type(document_type)).to eq([document])
    end

    it "returns an array with all documents, if there are" do
      document1 = instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
      document2 = instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
      expect(instance.documents_by_type(document_type)).to eq([document1, document2])
    end

    it "returns the document of the right document type" do
      document = instance.documents.create(document_type_id: document_type.id, asset: sample_asset)
      instance.documents.create(document_type_id: create(:document_type), asset: sample_asset)
      expect(instance.documents_by_type(document_type)).to eq([document])
    end
  end
end
