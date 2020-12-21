# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "add_product_upload_document_types"

RSpec.describe AddProductUploadDocumentTypes do
  let(:keys) do
    %w[
      product_update_general_information
      product_update_contribution
      product_update_addendum_insurance
      product_update_contract_status
      product_update_certificate
    ]
  end

  describe "#data" do
    it "creates a new feature" do
      described_class.new.data
      keys.each do |key|
        expect(DocumentType.find_by(key: key)).not_to be_nil
      end
    end
  end

  describe "#rollback" do
    it "does not raise an exception" do
      described_class.new.data
      described_class.new.rollback

      keys.each do |key|
        expect(DocumentType.find_by(key: key)).to be_nil
      end
    end
  end
end
