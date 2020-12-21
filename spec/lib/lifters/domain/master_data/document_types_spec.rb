# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::MasterData::DocumentTypes do
  subject { described_class }

  let(:document_type1) { DocumentType.find_by key: "vertragsinformation" }
  let(:document_type2) { DocumentType.find_by key: "nachtrag" }
  let(:document_type_by_template) { DocumentType.find_by template: "offer_mailer/offer_documents" }

  context "when try to change data" do
    it "should raise error" do
      document_type = subject.all.last

      expect { document_type.key = "another_key" }.to raise_error RuntimeError, "Can't modify frozen hash"
    end
  end

  describe ".find_by_key" do
    it "should find matching document type by the key" do
      expect(subject.find_by_key("vertragsinformation")).to eq document_type1
    end
  end

  describe ".find_by_template" do
    it "should find matching document type by the template" do
      expect(subject.find_by_template("offer_mailer/offer_documents")).to eq document_type_by_template
    end
  end

  describe ".select_by_keys" do
    it "should select matching document type by the keys" do
      keys = %w[
        nachtrag
        vertragsinformation
      ]

      expect(subject.select_by_keys(keys)).to match_array [document_type1, document_type2]
    end
  end

  describe ".select_visible_to_customer_by_keys" do
    it "should select only visible to customer matching document type by the keys" do
      keys = %w[
        nachtrag
        vertragsinformation
      ]

      expect(subject.select_visible_to_customer_by_keys(keys)).to match_array [document_type1]
    end
  end
end
