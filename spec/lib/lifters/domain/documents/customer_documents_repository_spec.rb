# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Rails/DynamicFindBy
RSpec.describe Domain::Documents::CustomerDocumentsRepository do
  subject { described_class.new(mandate) }

  let(:mandate) { create(:mandate) }

  it "should break without a mandate" do
    expect {
      described_class.new(nil)
    }.to raise_error("No mandate provided!")
  end

  describe "how to find a document attached to a product not in an offer state" do
    let(:product) { create(:product, mandate: mandate) }
    let(:document) { create(:document, documentable: product) }

    it "should find the product" do
      expect(subject.find_by_id_at_product(id: document.id, product_id: product.id)).to eq(document)
    end

    it "should return nil, if the product cannot be found" do
      expect(subject.find_by_id_at_product(id: document.id, product_id: product.id + 1)).to be_nil
    end

    it "should return the right document" do
      create(:document, documentable: product)
      expect(subject.find_by_id_at_product(id: document.id, product_id: product.id)).to eq(document)
    end

    it "should not return a document attached to a different mandate" do
      product.update_attributes!(mandate: create(:mandate))
      expect(subject.find_by_id_at_product(id: document.id, product_id: product.id)).to be_nil
    end
  end

  describe "how to find a document attached to a product in offer state" do
    let(:product) do
      opportunity = create(:opportunity_with_offer, mandate: mandate)
      opportunity.offer.offer_options.first.product
    end
    let(:document) { create(:document, documentable: product) }

    it "should find the product" do
      expect(subject.find_by_id_at_product(id: document.id, product_id: product.id)).to eq(document)
    end
  end
end
