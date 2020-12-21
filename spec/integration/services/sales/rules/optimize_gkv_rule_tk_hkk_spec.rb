# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a gkv product to be offered" do
  it "should be an offered gkv product" do
    expect(product).to be_a(Product)
    expect(product.premium_state).to eq("salary")
    expect(product.premium_period).to eq("none")
    expect(product.plan).to eq(plan)
    expect(plan.coverages).to_not be_empty
    expect(product.coverages).to match_array(plan.coverages)
    expect(product.persisted?).to be_truthy

    # should receive a copy of the coverages, not the original
    changed_value = ValueTypes::Text.new("Changed Value")
    product.coverages[sample_coverage_feature_id] = changed_value
    expect(plan.coverages[sample_coverage_feature_id]).to_not eq(changed_value)
  end
end

RSpec.describe Sales::Rules::OptimizeGkvRuleTkHkk, :integration do
  let(:sample_coverage_feature_id) { "boolean_247srvctlfn_4d2186" }

  let(:mandate) { create(:mandate, state: "accepted", gender: "female") }

  let(:product_stubbing) { {mandate: mandate, created_at: 1.hour.ago, advised?: true} }

  let(:sample_coverage_value) { ValueTypes::Text.new("Sample Coverage Text") }
  let(:coverages) { {sample_coverage_feature_id => sample_coverage_value} }

  let(:category_gkv) { create(:category_gkv) }

  let(:whitelist_company) do
    create(:company, gkv_whitelisted: true, national_health_insurance_premium_percentage: 1.5)
  end
  let(:whitelist_plan) do
    create(:plan, category: category_gkv, coverages: {sample_coverage_feature_id => ValueTypes::Boolean::TRUE},
           subcompany: create(:subcompany_gkv, company: whitelist_company))
  end
  let(:whitelist_product) do
    create(
      :product,
      plan:                whitelist_plan,
      created_at:          1.hour.ago,
      mandate:             mandate,
      coverages:           {sample_coverage_feature_id => ValueTypes::Boolean::TRUE},
      premium_price_cents: 0,
      premium_state:       "salary",
      premium_period:      "none"
    )
  end

  let(:unlisted_company) { create(:company, gkv_whitelisted: false) }
  let(:unlisted_plan) { create(:plan, category: category_gkv, coverages: {sample_coverage_feature_id => ValueTypes::Boolean::TRUE}, subcompany: create(:subcompany_gkv, company: unlisted_company)) }
  let(:unlisted_product) do
    create(
      :product,
      plan:                unlisted_plan,
      created_at:          1.hour.ago,
      mandate:             mandate,
      coverages:           {sample_coverage_feature_id => ValueTypes::Boolean::TRUE},
      premium_price_cents: 0,
      premium_state:       "salary",
      premium_period:      "none"
    )
  end

  let(:tk_subcompany) { create(:subcompany_gkv, name: "Techniker Krankenkasse", ident: "technfac6e4") }
  let!(:tk_plan) { create(:plan, category: category_gkv, subcompany: tk_subcompany, coverages: coverages) }

  let(:hkk_subcompany) { create(:subcompany_gkv, name: "Handelskrankenkasse (hkk)", ident: "handec9db4e") }
  let!(:hkk_plan) { create(:plan, category: category_gkv, subcompany: hkk_subcompany, coverages: coverages) }

  before do
    create(:advice, mandate: mandate, topic: whitelist_product)
    create(:advice, mandate: mandate, topic: unlisted_product)
  end

  context "on applicattion" do
    let(:subject) { Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: whitelist_product) }

    it "yields three offer options" do
      offer_options = [nil, nil, nil]

      subject.on_application do |option0, option1, option2|
        offer_options = [option0, option1, option2]
      end

      expect(offer_options[0]).to be_a(OfferOption)
      expect(offer_options[1]).to be_a(OfferOption)
      expect(offer_options[2]).to be_a(OfferOption)

      expect(offer_options[0].product.plan).to eq(tk_plan)
      expect(offer_options[1].product.plan).to eq(hkk_plan)
      expect(offer_options[2].product).to eq(whitelist_product)

      one_recommended = offer_options.map(&:recommended)

      expect(one_recommended.select { |recommend| recommend }.count).to eq(1)
    end
  end

  context "top_cover_and_price option" do
    let(:sample_coverage_feature_id) { "boolean_247srvctlfn_4d2186" }

    let!(:plan) { tk_plan }
    let(:subject) { Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: whitelist_product) }
    let(:option) { subject.send(:create_top_cover_and_price_offer_option) }
    let(:product) { option.product }

    before :each do
      expect(subject).to be_applicable
    end

    it_behaves_like "a gkv product to be offered"

    it "should create an offer option" do
      expect(option).to be_an(OfferOption)
      expect(option.top_cover_and_price?).to be_truthy
      expect(option.persisted?).to be_truthy
      expect(product.mandate).to be_nil
      expect(product.offered?).to be_truthy
    end
  end

  context "top_price option" do

    let!(:plan) { hkk_plan }

    let(:subject) { Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: whitelist_product) }
    let(:option) { subject.send(:create_top_price_offer_option) }
    let(:product) { option.product }

    before :each do
      expect(subject).to be_applicable
    end

    it_behaves_like "a gkv product to be offered"

    it "should create an offer option" do
      expect(option).to be_an(OfferOption)
      expect(option.top_price?).to be_truthy
      expect(option.persisted?).to be_truthy
      expect(product.mandate).to be_nil
      expect(product.offered?).to be_truthy
    end
  end

  context "old_product option" do

    let!(:wrong_admin) { create(:admin, id: 2) }

    let(:subject) { Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: whitelist_product) }
    let(:option) { subject.send(:create_old_product_option) }
    let(:product) { whitelist_product }
    let!(:plan) { whitelist_plan }

    it_behaves_like "a gkv product to be offered"

    it "should be an offer option" do
      expect(option).to be_an(OfferOption)
      expect(option.old_product?).to be_truthy
      expect(option.product).to eq(whitelist_product)
      expect(option.persisted?).to be_truthy
      expect(option.write_protected).to be_truthy
      expect(option.product.details_available?).to be_truthy
    end
  end
end
