# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentType, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "an auditable model"

  # State Machine
  # Scopes

  describe ".product_document_upload" do
    let(:document_types) do
      [
        DocumentType.request_document_reupload,
        DocumentType.contract_information,
        DocumentType.invoice,
        DocumentType.supplement,
        DocumentType.situation,
        DocumentType.certificate
      ]
    end

    it do
      expect(described_class.product_document_upload).to match_array document_types
    end
  end

  describe "#customer_uploaded" do
    it do
      document_type = DocumentType.policy
      expect(document_type).not_to be_customer_uploaded
    end

    context "when file extension is 'use_filename'" do
      it do
        document_type = DocumentType.customer_upload
        expect(document_type).to be_customer_uploaded
      end
    end

    context "when it belongs to one of the product_document_upload types" do
      it do
        document_type = DocumentType.contract_information
        expect(document_type).to be_customer_uploaded
      end
    end
  end

  # Associations

  it { is_expected.to have_many(:documents) }

  describe "A document_type" do
    let(:document_type) { create(:document_type) }

    it "is not destroyed if it is associated with documents" do
      document_type.documents << create(:document)
      document_type.destroy
      expect(document_type.errors[:base].count).to eq(1)
      expect(DocumentType.find_by(id: document_type.id)).to eq(document_type)
    end

    it "is destroyed if is not associated with documents" do
      document_type.destroy
      expect(DocumentType.find_by(id: document_type.id)).to be_nil
    end
  end

  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:key) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_uniqueness_of(:key) }
  it { is_expected.to validate_uniqueness_of(:template) }

  it "is invalid with an incorrect template" do
    doc_type = build_stubbed(:document_type, template: "adsfdk")
    doc_type.valid?
    expect(doc_type.errors[:template].first).to eq(I18n.t("template_file_must_exist"))
  end

  it "is valid with a blank template" do
    doc_type = build_stubbed(:document_type, template: "")
    expect(doc_type.valid?).to eq(true)
  end

  it "is valid with a correct template" do
    file_path = "app/views/valid.html.haml"
    File.new(file_path, "w")
    doc_type = build_stubbed(:document_type, template: "valid")
    expect(doc_type.valid?).to eq(true)
    File.delete(file_path)
  end

  (described_class::EXPOSABLE_MANDATE_DOC_TYPES + described_class::EXPOSABLE_PRODUCT_DOC_TYPES)
    .each do |type|
    it "has exposable document type #{type} using by partnership API" do
      expect(DocumentType.find_by(key: type)).not_to eq(nil)
    end
  end

  describe ".allowed_to_customer", :integration do
    let!(:document_types) do
      [
        create(:document_type, :visible_to_prospect_customer),
        create(:document_type, :visible_to_mandate_customer)
      ]
    end

    it "returns document types based on customer state" do
      expect(described_class.allowed_to_customer("prospect")).to include(document_types[0])
      expect(described_class.allowed_to_customer("mandate_customer")).to include(document_types[1])
      expect(described_class.allowed_to_customer(nil)).to include(document_types[1])
    end
  end
end
