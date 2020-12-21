# frozen_string_literal: true

require "rails_helper"

require "migration_data/testing"
require_migration "remove_duplicated_document_types"

RSpec.describe RemoveDuplicatedDocumentTypes, :integration do
  describe "#data" do
    let(:duplicated_keys_mapper) do
      {
        "vertragsinformation" => "product_update_general_information",
        "BEITRAG" => "product_update_contribution",
        "nachtrag" => "product_update_addendum_insurance",
        "STAND" => "product_update_contract_status",
        "BESCHEINIGUNG" => "product_update_certificate"
      }
    end

    before do
      # Create duplicated document types
      duplicated_keys_mapper.each do |_, duplicated_key|
        create :document_type, key: duplicated_key
      end

      # Assign documents both to the origin and duplicated document type
      duplicated_keys_mapper.each do |original_key, duplicated_key|
        create :document, document_type: DocumentType.find_by(key: original_key)
        create :document, document_type: DocumentType.find_by(key: duplicated_key)
      end

      described_class.new.data
    end

    it "removes all duplicated document types" do
      duplicated_keys_mapper.each do |_, duplicated_key|
        expect(DocumentType.find_by(key: duplicated_key)).to be_nil
      end
    end

    it "assign the documents of the duplicated document types to the original" do
      duplicated_keys_mapper.each do |original_key, _|
        original_document_type = DocumentType.find_by(key: original_key)
        expect(original_document_type.documents.count).to eq(2)
      end
    end
  end
end
