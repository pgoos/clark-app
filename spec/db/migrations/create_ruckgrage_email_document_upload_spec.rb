# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "create_ruckfrage_email_document_upload"

RSpec.describe CreateRuckfrageEmailDocumentUpload, :integration do
  let(:key) { "product_mailer-request_document_reupload" }

  describe "#data" do
    it "creates a new feature" do
      described_class.new.rollback
      described_class.new.data
      expect(DocumentType.find_by(key: key)).not_to be_nil
    end
  end

  describe "#rollback" do
    it "does not raise an exception" do
      described_class.new.rollback

      expect(DocumentType.find_by(key: key)).to be_nil
    end
  end
end
