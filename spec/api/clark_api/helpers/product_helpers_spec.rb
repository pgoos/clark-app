# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::Helpers::ProductHelpers do
  let(:clazz) { Class.new { extend ClarkAPI::Helpers::ProductHelpers } }

  let(:category_with_features) do
    create(:category, ident: "afe225d9", name: "Privathaftpflichtversicherung", coverage_features: coverage_features)
  end

  let(:plan) { create(:plan, category: category_with_features) }

  let(:product) do
    create(:product, {
      plan: plan,
      premium_period: :year,
      premium_price: 100.00,
      coverages: { "money_dckngssmmprsnnschdn_c4d961" => ValueTypes::Money.new(4_000_000, "EUR") }
    })
  end

  describe "#product_coverages" do
    shared_examples "match coverages" do
      it "returns a list of formatted covarages" do
        result = clazz.product_coverages(product)

        expect(result).to eq(expected_format)
      end
    end

    context "when product has no coverages" do
      let(:expected_format) { nil }
      let(:coverage_features) { [] }

      it_behaves_like "match coverages"
    end

    context "when product has coverages" do
      let(:expected_format) do
        [
          {
            type: "Money",
            value: "4.000.000,00 €",
            name: "Deckungssumme Personenschäden"
          }
        ]
      end

      let(:coverage_features) do
        [
          CoverageFeature.new(
            value_type: "Money",
            name: "Deckungssumme Personenschäden",
            definition: "Deckungssumme Personenschäden",
            identifier: "money_dckngssmmprsnnschdn_c4d961"
          )
        ]
      end

      it_behaves_like "match coverages"
    end
  end
end
