# frozen_string_literal: true

require "rails_helper"
require_relative "with_utility_extension"

RSpec.describe Domain::OfferGeneration::Util::BuildOfferOption do
  include_context "with utility extension"

  subject { with_utility_extension.(offer, Domain::OfferGeneration::Util::BuildOfferOption) }

  let(:plan_ident1) { "ident1" }
  let(:plan1) { build_stubbed(:plan, :with_stubbed_coverages, ident: plan_ident1) }
  let(:now) { Time.zone.now }
  let(:contract_begin) { now.beginning_of_day + 1.day }

  before do
    Timecop.freeze(now)
    allow_any_instance_of(::OfferGeneration::PlansRepository)
      .to receive(:find_by_ident)
      .with(plan_ident1)
      .and_return(plan1)
  end

  after { Timecop.return }

  it "builds an offer option" do
    option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin)
    expect(option).to be_an(OfferOption)
  end

  it "sets as not recommended if not flagged" do
    option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin)
    expect(option).not_to be_recommended
  end

  it "sets as recommended if flagged" do
    option = subject.build_offer_option(plan_ident: plan_ident1, is_recommended: true, contract_begin: contract_begin)
    expect(option).to be_recommended
  end

  it "builds a product with the plan" do
    option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin)
    expect(option.plan_ident).to eq(plan_ident1)
  end

  it "sets only the active coverages" do
    # make one of the coverage_features inactive
    coverage_feature = plan1.category.coverage_features.first
    coverage_feature.valid_until = Date.yesterday

    option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin)
    expect(option.coverages[coverage_feature.identifier]).to be(nil)
  end

  it "sets the premium" do
    option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin)
    expect(option.premium_price).to eq(plan1.premium_price)
    expect(option.premium_period).to eq(plan1.premium_period)
  end

  it "does not set default offer option" do
    option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin)
    expect(option.option_type).to be_nil
  end

  it "sets the contract start date" do
    option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin)
    expect(option.contract_begin).to eq(contract_begin)
  end

  it "uses the default offer attributes for the product" do
    option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin)
    actual_attributes = option.product.attributes.with_indifferent_access
    expected_attributes = Product.default_offer_attributes.compact.except(:coverages)

    expect(actual_attributes).to include(expected_attributes)
  end

  describe "with gkv category" do
    let(:category) { build_stubbed(:category_gkv) }
    let(:plan1) do
      build_stubbed(:plan, :with_stubbed_coverages,
                    premium_price: 0, category: category, ident: plan_ident1)
    end

    it "builds valid products" do
      option = subject.build_offer_option(plan_ident: plan_ident1, contract_begin: contract_begin,
                                          option_type: :top_cover)
      expect(option.valid?).to eq(true)
      expect(option.product.premium_state).to eq "salary"
    end
  end
end
