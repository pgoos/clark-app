require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::Product do
  subject { described_class }

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

  context "#coverages" do
    let(:expected_value) do
      {
        "money_dckngssmmprsnnschdn_c4d961" => "4.000.000,00 €"
      }
    end

    it { is_expected.to expose(:coverages).of(product).as(Hash).with_value(expected_value) }
  end
end
