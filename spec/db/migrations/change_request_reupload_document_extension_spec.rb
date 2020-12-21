# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "change_request_reupload_document_extension"

RSpec.describe ChangeRequestReuploadDocumentExtension do
  describe "#data" do
    context "with document" do
      it "changes its extension to use_filename" do
        document_type = DocumentType.request_document_reupload
        described_class.new.data
        expect(document_type.reload.extension).to eq("use_filename")
      end
    end

    context "without document" do
      it "runs without failing" do
        allow(DocumentType).to receive(:request_document_reupload).and_return(nil)
        expect { described_class.new.data }.not_to raise_error
      end
    end
  end

  describe "#rollback" do
    context "with document" do
      it "changes its extension back to pdf" do
        document_type = DocumentType.request_document_reupload
        described_class.new.data
        described_class.new.rollback
        expect(document_type.reload.extension).to eq("pdf")
      end
    end

    context "without document" do
      it "runs without failing" do
        allow(DocumentType).to receive(:request_document_reupload).and_return(nil)
        described_class.new.data
        expect { described_class.new.rollback }.not_to raise_error
      end
    end
  end
end
