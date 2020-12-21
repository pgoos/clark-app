# frozen_string_literal: true

require "rails_helper"

describe DocumentsRepository do
  subject { described_class.new }

  let(:product) { create(:product) }

  describe "#exists_cover_note?" do
    context "when exists cover note" do
      before do
        create(:document, :cover_note, documentable: product)
      end

      it "returns true" do
        value = described_class.exists_cover_note?(product.id)

        expect(value).to be true
      end
    end

    context "when there is no cover note" do
      it "returns false" do
        value = described_class.exists_cover_note?(product.id)

        expect(value).to be false
      end
    end
  end

  describe "customer_uploaded" do
    context "when document_type is customer_upload" do
      context "when documentable is product" do
        context "when uploaded_at after Jan 31st 2019" do
          context "when product with analysis_state nil (Clark1 case)" do
            let(:last_uploaded_document) do
              create(:document,
                     :customer_upload,
                     documentable: product,
                     created_at: Date.new(2019, 2, 2))
            end
            let!(:documents) do
              create_list(:document, 2,
                          :customer_upload,
                          documentable: product,
                          created_at: Date.new(2019, 2, 1))
            end

            it "match documents" do
              expect(subject.customer_uploaded).to match_array documents
            end

            it "orders by created_at" do
              create(:document, :customer_upload, documentable: product, created_at: Date.new(2019, 2, 1))
              last_uploaded_document

              expect(subject.customer_uploaded.last).to eq last_uploaded_document
            end
          end

          context "when contract with analysis_state 'details complete' (Clark1 case)" do
            let(:contract_details_complete) { create(:contract, :details_complete) }
            let!(:documents) do
              create_list(:document, 2,
                          :customer_upload,
                          documentable_type: "Product",
                          documentable_id: contract_details_complete.id,
                          created_at: Date.new(2019, 2, 1))
            end

            it "match documents" do
              expect(subject.customer_uploaded).to match_array documents
            end
          end
        end
      end
    end

    context "when document_type is not customer_upload" do
      before do
        @documents = create_list(:document, 2, documentable: product, created_at: Date.new(2019, 2, 1))
      end

      it { expect(subject.customer_uploaded).not_to match_array @documents }
    end

    context "when documentable is not product" do
      before do
        mandate = create(:mandate)
        @documents = create_list(:document, 2, :customer_upload,
                                 documentable: mandate,
                                 created_at: Date.new(2019, 2, 1))
      end

      it { expect(subject.customer_uploaded).not_to match_array @documents }
    end

    context "when uploaded before Jan 31st 2019" do
      before do
        @documents = create_list(:document, 2, :customer_upload,
                                 documentable: product,
                                 created_at: Date.new(2019, 1, 30))
      end

      it { expect(subject.customer_uploaded).not_to match_array @documents }
    end

    context "when product with analysis_state neither nil nor 'details complete'" do
      let(:contract_under_analysis) { create(:contract, :under_analysis) }
      let!(:documents) do
        create_list(:document, 2,
                    :customer_upload,
                    documentable_type: "Product",
                    documentable_id: contract_under_analysis.id,
                    created_at: Date.new(2019, 2, 1))
      end

      it { expect(subject.customer_uploaded).not_to match_array documents }
    end
  end

  describe "#documents_by" do
    let(:inquiry_category) { create(:inquiry_category) }
    let(:documents) { create_list(:document, 2, :customer_upload, documentable: inquiry_category) }

    it "returns expected documents" do
      docs = described_class.documents_by(
        documentable_id: inquiry_category.id,
        documentable_type: "InquiryCategory",
        id: documents.map(&:id)
      )

      expect(docs.size).to be(documents.size)

      docs.each do |doc|
        document = documents.find { |d| d.id == doc.id }

        expect(doc.name).to eq(document.name)
        expect(doc.asset.read).to eq(document.asset.file.read)
      end
    end
  end

  describe "#find_by_owner_and_type" do
    let(:inquiry_category) { create(:inquiry_category) }

    before do
      create(:document, :customer_upload)
      create_list(:document, 2, :customer_upload, documentable: inquiry_category)
    end

    it "returns expected documents" do
      docs = described_class.find_by_owner_and_type(
        inquiry_category.id,
        "InquiryCategory",
        "CUSTOMER"
      )

      expect(docs.size).to be(inquiry_category.documents.size)

      docs.each do |doc|
        document = inquiry_category.documents.find { |d| d.id == doc.id }

        expect(doc.name).to eq(document.name)
        expect(doc.asset.read).to eq(document.asset.file.read)
      end
    end
  end

  describe "#save_customer_uploaded_file!" do
    let(:inquiry_category) { create(:inquiry_category) }
    let(:document) { build(:document, :customer_upload, documentable: inquiry_category) }

    it "saves a new documents" do
      struct = Structs::Document.new(
        name: document.name,
        documentable_id: document.documentable_id,
        documentable_type: document.documentable_type,
        asset: document.asset
      )

      expect {
        described_class.save_customer_uploaded_file!(struct)
      }.to change(Document, :count).by(1)
    end
  end

  describe "destroy_by" do
    let(:inquiry_category) { create(:inquiry_category) }

    before do
      create_list(:document, 2, :customer_upload, documentable: inquiry_category)
    end

    it "removes document(s) from database" do
      document_ids = Document.all.pluck(:id)

      expect {
        described_class.destroy_by(
          documentable_id: inquiry_category.id,
          documentable_type: inquiry_category.class.to_s,
          id: document_ids
        )
      }.to change(Document, :count).from(2).to(0)
    end
  end
end
