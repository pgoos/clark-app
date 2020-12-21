# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::InquiryCategoriesRepository do
  subject(:repo) { described_class.new }

  context "when inquiry has multiple categories" do
    let(:inquiry) { build_stubbed :inquiry, :in_creation }

    let(:inquiry_category1) { build_stubbed :inquiry_category, inquiry: inquiry, category_id: 11 }
    let(:inquiry_category2) { build_stubbed :inquiry_category, inquiry: inquiry, category_id: 12 }

    before do
      allow(inquiry).to receive(:inquiry_categories).and_return \
        [inquiry_category1, inquiry_category2]
    end

    it "includes all inquiry categories" do
      expect(described_class.new.all(inquiry, [])).to \
        match_array [inquiry_category1, inquiry_category2]
    end

    context "when products have been created for an inquiry" do
      it "does not include inquery category which products belong to" do
        products = [
          build_stubbed(:product, plan: build_stubbed(:plan, category_id: 2)),
          build_stubbed(:product, inquiry: inquiry, plan: build_stubbed(:plan, category_id: 12))
        ]

        expect(described_class.new.all(inquiry, products)).to \
          match_array [inquiry_category1]
      end
    end

    context "when inquiry category was deleted by customer" do
      let(:inquiry_category2) { build_stubbed :inquiry_category, deleted_by_customer: true }

      it "does not include it" do
        expect(described_class.new.all(inquiry, [])).to \
          match_array [inquiry_category1]
      end
    end
  end
end
