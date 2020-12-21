# frozen_string_literal: true

require "rails_helper"

RSpec.describe "pdf_generator/comparison_document.html.haml", :integration do
  let(:coverage_feature1) { build(:coverage_feature, identifier: "cov1", name: "cov feat name 1", value_type: "Int") }
  let(:coverage_feature2) { build(:coverage_feature, identifier: "cov2", name: "cov feat name 2", value_type: "Int") }
  let(:coverage_feature3) { build(:coverage_feature, identifier: "cov3", name: "cov feat name 3", value_type: "Int") }
  let(:coverage_features) { [coverage_feature1, coverage_feature2, coverage_feature3] }
  let(:category_name) { "category name" }
  let(:category) { create(:category, name: category_name, coverage_features: coverage_features) }

  let(:company1) { create(:company, ident: "company1", name: "Company name 1") }
  let(:company2) { create(:company, ident: "company2", name: "Company name 2") }
  let(:company3) { create(:company, ident: "company3", name: "Company name 3") }
  let(:companies) { [company1, company2, company3] }

  let(:plan1) { create(:plan, ident: "plan1", category: category, company: company1) }
  let(:plan2) { create(:plan, ident: "plan2", category: category, company: company2) }
  let(:plan3) { create(:plan, ident: "plan3", category: category, company: company3) }

  let(:product1) { build(:product, plan: plan1, state: "offered", coverages: product1_coverages) }
  let(:product1_coverages) do
    {
      coverage_feature1.identifier => ValueTypes::Int.new(11),
      coverage_feature2.identifier => ValueTypes::Int.new(12),
      coverage_feature3.identifier => ValueTypes::Int.new(13)
    }
  end
  let(:product2) { build(:product, plan: plan2, state: "offered", coverages: product2_coverages) }
  let(:product2_coverages) do
    {
      coverage_feature1.identifier => ValueTypes::Int.new(21),
      coverage_feature2.identifier => ValueTypes::Int.new(22),
      coverage_feature3.identifier => ValueTypes::Int.new(23)
    }
  end
  let(:product3) { build(:product, plan: plan3, state: "offered", coverages: product3_coverages) }
  let(:product3_coverages) do
    {
      coverage_feature1.identifier => ValueTypes::Int.new(31),
      coverage_feature2.identifier => ValueTypes::Int.new(32),
      coverage_feature3.identifier => ValueTypes::Int.new(33)
    }
  end
  let(:products) { [product1, product2, product3] }

  let(:offer_option1) { build(:offer_option, product: product1, recommended: true) }
  let(:offer_option2) { build(:offer_option, product: product2) }
  let(:offer_option3) { build(:offer_option, product: product3) }
  let(:offer_options) { [offer_option1, offer_option2, offer_option3] }

  let(:mandate) { build_stubbed(:mandate, :accepted) }
  let(:opportunity) { build_stubbed(:opportunity, mandate: mandate, category: category) }
  let(:offer1) do
    Offer.new(
      opportunity: opportunity,
      offer_options: offer_options,
      displayed_coverage_features: coverage_features.map(&:identifier)
    )
  end

  it "render the comparison pdf" do
    render template: "pdf_generator/comparison_document.html.haml", locals: {offer: offer1}

    companies.each do |company|
      expect(rendered).to match(%r{<th>\s*#{company.name}\s*</th>})
    end

    products.each do |product|
      price = ValueTypes::Money.new(product.premium_price.to_f, product.premium_price.currency.to_s)
      expect(rendered).to match(%r{<th>\s*#{product.plan_name}\s*<br>\s*#{price}\s*</th>})
    end

    coverage_features.each do |coverage_feature|
      c_name = coverage_feature.name
      c1 = product1_coverages[coverage_feature.identifier]
      c2 = product2_coverages[coverage_feature.identifier]
      c3 = product3_coverages[coverage_feature.identifier]
      expect(rendered).to match(%r{<td>\s*#{c_name}\s*</td>\D*#{c1}\D*#{c2}\D*#{c3}})
    end
  end
end
