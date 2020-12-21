# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "create_retirement_product_analysed_mailer"

RSpec.describe CreateRetirementProductAnalysedMailer, :integration do
  let(:key) { "retirement_product_mailer-retirement_product_analysed" }

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
