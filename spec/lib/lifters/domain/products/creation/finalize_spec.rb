# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::Creation::Finalize do
  context "with inquiry" do
    let(:product) { build_stubbed :product, inquiry: inquiry }
    let(:inquiry) { build_stubbed :inquiry }

    it "finalizes an inquiry" do
      finalizor = instance_double Domain::Inquiries::Finalization
      expect(Domain::Inquiries::Finalization).to receive(:new).with(inquiry).and_return finalizor
      expect(finalizor).to receive(:perform_product_related_completion).with(product)

      described_class.new.(product)
    end
  end

  context "when product has retirement category" do
    let(:product) { create :product, category: create(:category, :direktversicherung_classic) }

    it "creates a retirement extension" do
      described_class.new.(product)

      expect(product.retirement_product).to be_present
      expect(product.retirement_product).to be_persisted
      expect(product.retirement_product).to be_kind_of Retirement::CorporateProduct
      expect(product.retirement_product).to be_created
    end
  end
end
