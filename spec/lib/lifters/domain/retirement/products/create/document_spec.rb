# frozen_string_literal: true

require "rails_helper"

describe Domain::Retirement::Products::Create::Document do
  subject { described_class.new(mandate) }

  let(:mandate) { create(:mandate) }

  describe "#call" do
    it "begins with no associations" do
      expect(mandate.products.count).to be_zero
      expect(mandate.retirement_products.count).to be_zero
    end

    context "when valid mandate and documents" do
      let(:documents) do
        create_list(:document, 2, :retirement_document, documentable: mandate)
      end

      before { subject.call(documents.map(&:id)) }

      it { expect(mandate.products.count).to eq(1) }

      it { expect(mandate.retirement_products.count).to eq(1) }

      it "associates document_ids with retirement product" do
        product = mandate.products.last

        expect(mandate.reload.documents.count).to eq(0)
        expect(product.documents.count).to eq(2)
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
