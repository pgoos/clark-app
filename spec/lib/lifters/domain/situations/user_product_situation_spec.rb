# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Situations::UserProductSituation do
  subject { Domain::Situations::UserSituation.new(mandate) }

  let(:mandate) { create(:mandate) }

  context "has_product_in_these_states?" do
    # TODO: test the other states as well
    before { create :product_gkv, state: "under_management", mandate: mandate }

    it "with mandate with nil interactions" do
      result = subject.has_product_in_these_states?(Category.gkv.ident, ["under_management"])
      expect(result).to eq(true)
    end
  end

  context "gkv_product_without_offer?" do
    before { create :product_gkv, state: "under_management", mandate: mandate }

    it "without offer" do
      # TODO: test with offer
      result = subject.gkv_product_without_offer?
      expect(result).to eq(true)
    end
  end

  context "open_opportunities_from_categories?" do
    before do
      product = create :product_gkv, state: "under_management", mandate: mandate
      create :opportunity, old_product: product, category: Category.gkv, mandate: mandate
    end

    it "true if there is an opportunity" do
      # TODO: test variation of category
      # TODO: test variation of not having an opportunity
      result = subject.open_opportunities_from_categories?([Category.gkv])
      expect(result).to eq(true)
    end
  end
end
