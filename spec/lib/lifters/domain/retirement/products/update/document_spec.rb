# frozen_string_literal: true

require "rails_helper"

describe Domain::Retirement::Products::Update::Document do
  subject { described_class.new(mandate, product) }

  let(:mandate) { create(:mandate) }
  let(:product) { create(:product, :retirement_state_category, mandate: mandate) }
  let!(:retirement_product) { create :retirement_product, product: product }

  describe "#call" do
    let(:documents) do
      create_list(:document, 2, :retirement_document, documentable: mandate)
    end

    context "when valid mandate and documents" do
      before { subject.call(documents.map(&:id)) }

      it "associates document_ids with product" do
        expect(mandate.reload.documents.count).to eq(0)
        expect(product.documents.count).to eq(2)
      end

      it "updates state of retirement extension" do
        expect(product.retirement_product).to be_created
      end
    end

    context "without retirement extension" do
      let!(:retirement_product) { nil }

      it "creates an extension" do
        subject.call(documents.map(&:id))
        expect(product.retirement_product).to be_present
        expect(product.retirement_product).to be_kind_of Retirement::StateProduct
      end
    end

    context "when documents doesn't belong to mandate" do
      let(:documents) { create_list(:document, 2, :retirement_document) }

      it "raises DocumentOwnerError" do
        expect { subject.call(documents.map(&:id)) }.to raise_error(Domain::Retirement::Products::DocumentOwnerError)
      end
    end
  end
end
