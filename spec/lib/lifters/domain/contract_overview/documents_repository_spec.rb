# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::DocumentsRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#all" do
    let(:document_type1) { create(:document_type, :visible_to_mandate_customer, key: "DT1") }
    let(:document_type2) { create(:document_type, key: "DT2") }
    let(:document_type3) { create(:document_type, :visible_to_mandate_customer, key: "DT3") }

    let(:document5) { create(:document, document_type: document_type1) }
    let(:document6) { create(:document, document_type: document_type2) }

    let(:parent_plan) { create(:parent_plan, documents: [document5, document6]) }
    let(:plan) { create(:plan, parent_plan: parent_plan) }
    let(:product) { create :product, plan: plan }

    let!(:document1) { create(:document, documentable: product, document_type: document_type1) }
    let!(:document2) { create(:document, documentable: product, document_type: document_type1) }
    let!(:document3) { create(:document, documentable: product, document_type: document_type2) }
    let!(:document4) { create(:document, documentable: product, document_type: document_type3) }

    context "only_allowed_for_customer=true provided" do
      context "mandate accepted" do
        let(:product) { create(:product, plan: plan, mandate: create(:mandate, :accepted)) }

        it "filters documents out according available to customer document types" do
          documents = repo.all(product: product)

          expect(documents).to include(document1, document2, document4, document5)
          expect(documents.count).to eq(4)
        end
      end

      context "mandate created" do
        let(:product) { create(:product, plan: plan, mandate: create(:mandate, :created)) }

        it "filters documents out according available to customer document types" do
          documents = repo.all(product: product)

          expect(documents).to include(document1, document2, document4, document5)
          expect(documents.count).to eq(4)
        end
      end

      context "mandate not accepted" do
        it "filters documents out according available to customer document types" do
          expect(repo.all(product: product)).to be_empty
        end
      end
    end

    it "returns all documents" do
      documents = repo.all(product: product, only_allowed_for_customer: false)

      expect(documents).to include(document1, document2, document3, document4, document5, document6)
      expect(documents.count).to eq(6)
    end
  end
end
