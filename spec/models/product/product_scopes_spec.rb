# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  subject { product }

  let(:product) { create(:product, inquiry: create(:inquiry)) }

  context ".except_gkv" do
    it "does not show gkv products" do
      product = create(:product_gkv)

      expect(Product.except_gkv).not_to include(product)
    end

    it "it does not show product that is not gkv" do
      create(:category_gkv)
      product = create(:product)

      expect(Product.except_gkv).to include(product)
    end
  end

  describe ".for_robo_advisor" do
    let(:not_advisable_ident)    { described_class::ROBO_CANNOT_ADVISE.sample }
    let(:advisable_category)     { create(:category, ident: "advisable") }
    let(:non_advisable_category) { create(:category, ident: not_advisable_ident) }

    let(:mandate) { create(:mandate, state: "accepted") }
    let(:state_active) { described_class::STATES_OF_ACTIVE_PRODUCTS.sample }

    let!(:product) do
      create(
        :product,
        :sold_by_others,
        category: advisable_category,
        mandate: mandate,
        state: state_active
      )
    end

    it "finds product if category is advisable" do
      expect(described_class.for_robo_advisor(advisable_category.ident)).to include(product)
    end

    it "does not find products for non advisable categories" do
      product.update(category: non_advisable_category)

      expect(described_class.for_robo_advisor(non_advisable_category.ident)).not_to include(product)
    end

    it "still finds products if only one category is non advisable" do
      categories = [non_advisable_category, advisable_category].map(&:ident)
      expect(described_class.for_robo_advisor(categories)).to include(product)
    end

    it "still finds products if only one category is non advisable and we pass ids" do
      categories = [non_advisable_category, advisable_category].map(&:ident)
      expect(described_class.for_robo_advisor(categories)).to include(product)
    end

    it "finds products if we pass idents" do
      expect(described_class.for_robo_advisor(advisable_category.ident)).to include(product)
    end

    it "returns no products if we pass an non advisable id" do
      expect(described_class.for_robo_advisor(non_advisable_category.ident).count).to eq(0)
    end

    it "returns no products if no category is passed" do
      expect(described_class.for_robo_advisor([]).count).to eq(0)
    end

    it "returns no products if nil is passed as category" do
      expect(described_class.for_robo_advisor(nil).count).to eq(0)
    end

    context "when there is a previous advice" do
      before do
        create :advice, :created_by_robo_advisor, product: product, created_at: 2.days.ago
      end

      it "does not return the product" do
        expect(described_class.for_robo_advisor(advisable_category.ident)).not_to include(product)
      end

      context "when last advice is invalid" do
        before do
          create :advice, :created_by_robo_advisor, :invalid, product: product, created_at: 1.day.ago
        end

        it "returns the product" do
          expect(described_class.for_robo_advisor(advisable_category.ident)).to include(product)
        end
      end

      context "when there is invalid advice before last one" do
        before do
          create :advice, :created_by_robo_advisor, :invalid, product: product, created_at: 3.day.ago
        end

        it "does not return the product" do
          expect(described_class.for_robo_advisor(advisable_category.ident)).not_to include(product)
        end
      end
    end

    context "with customer_provided products" do
      let(:customer_provided_product) do
        create(
          :product,
          :sold_by_others,
          category: advisable_category,
          mandate: mandate,
          state: "customer_provided",
          analysis_state: "details_complete"
        )
      end

      it "finds product with state customer_provided, analysis_state details_complete" do
        result = described_class.for_robo_advisor(advisable_category.ident)

        expect(result).to include(customer_provided_product)
        expect(result.count).to eq(2)
      end
    end
  end

  it "should order products by creation_time" do
    product1 = create(:product)
    product2 = create(:product)
    expect(Product.ordered_by_creation_time).to match_array([product1, product2])
  end

  context ".takeover_possible" do
    it "returns empty relation if takeover is not possible for all products" do
      create_list(:product, 3, takeover_possible: false)
      expect(Product.takeover_possible.count).to eq(0)
    end

    it "returns a products relation with takeover possibility" do
      create(:product, takeover_possible: nil)
      create(:product, takeover_possible: true)
      create(:product, takeover_possible: false)
      expect(Product.takeover_possible.count).to eq(2)
    end
  end

  describe ".last_advice_invalid_or_does_not_exist" do
    let(:product) { create :product }

    context "with advices" do
      context "when last advice is valid" do
        before { create :advice, :created_by_robo_advisor, :valid, product: product, created_at: 1.days.ago }

        it "does not include the product" do
          expect(described_class.last_advice_invalid_or_does_not_exist).not_to include product
        end

        context "when there is invalid advice sent before last one" do
          before { create :advice, :created_by_robo_advisor, :invalid, product: product, created_at: 2.days.ago }

          it "does not include the product" do
            expect(described_class.last_advice_invalid_or_does_not_exist).not_to include product
          end
        end
      end

      context "when last advice is invalid" do
        before { create :advice, :created_by_robo_advisor, :invalid, product: product, created_at: 1.days.ago }

        it "includes the product" do
          expect(described_class.last_advice_invalid_or_does_not_exist).to include product
        end
      end

      context "when advice is reoccurring" do
        before { create :advice, :reoccurring_advice, :invalid, product: product, created_at: 1.days.ago }

        it "does not include the product" do
          expect(described_class.last_advice_invalid_or_does_not_exist).not_to include product
        end
      end
    end

    context "without advices" do
      it "includes the product" do
        expect(described_class.last_advice_invalid_or_does_not_exist).to include product
      end
    end
  end
end
