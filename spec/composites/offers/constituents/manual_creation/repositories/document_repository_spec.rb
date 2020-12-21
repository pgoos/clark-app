# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/repositories/document_repository"

RSpec.describe Offers::Constituents::ManualCreation::Repositories::DocumentRepository, :integration do
  subject { described_class.new }

  let(:document_type) { create(:document_type) }
  let(:opportunity) { create(:opportunity_with_offer) }
  let(:offer) { opportunity.offer }

  let(:file) do
    fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
  end

  let(:product) { offer.offer_options.first.product }

  describe "#create_or_update!" do
    context "create document" do
      it do
        # raises exception for invalid product_id
        expect {
          subject.create_or_update!(
            product_id:       9_999_999_999,
            document_type_key: document_type.key,
            file:             file
          )
        }.to raise_error(Utils::Repository::Errors::ValidationError)

        # raises exception for invalid document_type_key
        expect {
          subject.create_or_update!(
            product_id:       product.id,
            document_type_key: 9_999_999_999,
            file:             file
          )
        }.to raise_error(Utils::Repository::Errors::Error)

        # raises exception for invalid file
        expect {
          subject.create_or_update!(
            product_id:       product.id,
            document_type_key: document_type.key,
            file:             nil
          )
        }.to raise_error(Utils::Repository::Errors::ValidationError)

        # raises exception for missing product_id
        expect {
          subject.create_or_update!(
            document_type_key: document_type.key,
            file:             nil
          )
        }.to raise_error(ArgumentError)

        # raises exception for missing document_type_key
        expect {
          subject.create_or_update!(
            product_id:       product.id,
            file:             nil
          )
        }.to raise_error(ArgumentError)

        # raises exception for missing file
        expect {
          subject.create_or_update!(
            product_id:       product.id,
            document_type_key: document_type.key
          )
        }.to raise_error(ArgumentError)

        # returns document for valid params
        expect(
          subject.create_or_update!(
            product_id:       product.id,
            document_type_key: document_type.key,
            file:             file
          )
        ).to be_a(Offers::Constituents::ManualCreation::Entities::Document)
      end
    end

    context "update document" do
      let!(:contract_information_document) do
        create :document, document_type: DocumentType.contract_information, documentable: product
      end

      let(:file_for_update) do
        fixture_file_upload(Rails.root.join("spec", "fixtures", "dummy-mandate.pdf"))
      end

      it do
        # updates the file of the document
        subject.create_or_update!(
          product_id:       product.id,
          document_type_key: contract_information_document.document_type.key,
          file:             file_for_update
        )

        updated_document = contract_information_document.reload

        expect(updated_document.url).to include("dummy-mandate.pdf")
      end
    end
  end

  describe "#delete!" do
    let!(:document) do
      create :document, documentable: product
    end

    it do
      # decrements count of the documents
      expect { subject.delete!(document.id) }.to change(Document, :count).by(-1)
    end
  end

  describe "#find" do
    let!(:document) do
      create :document, documentable: product
    end

    it do
      # selects the document
      expect(subject.find(document.id)).to be_a(Offers::Constituents::ManualCreation::Entities::Document)
    end
  end
end
