# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  # Setup ------------------------------------------------------------------------------------------

  subject { product }
  let(:product) { FactoryBot.build_stubbed(:product, inquiry: FactoryBot.build_stubbed(:inquiry)) }

  # Delegates --------------------------------------------------------------------------------------

  it { is_expected.to delegate_method(:user).to(:mandate) }
  it { is_expected.to delegate_method(:category_id).to(:plan) }
  it { is_expected.to delegate_method(:category_ident).to(:plan) }
  it { is_expected.to delegate_method(:vertical_ident).to(:plan) }
  it { is_expected.to delegate_method(:company_id).to(:plan) }
  it { is_expected.to delegate_method(:company_ident).to(:plan) }
  it { is_expected.to delegate_method(:subcompany_id).to(:plan) }
  it { is_expected.to delegate_method(:owner_ident).to(:mandate) }
  it { is_expected.to delegate_method(:accessible_by).to(:mandate) }
  it { is_expected.to delegate_method(:accessible_by?).to(:mandate) }
  it { is_expected.to delegate_method(:national_health_insurance_premium_percentage).to(:company) }
  it { is_expected.to delegate_method(:company_name).to(:company).as(:name) }
  it { is_expected.to delegate_method(:subcompany_name).to(:subcompany).as(:name) }
  it { is_expected.to delegate_method(:plan_name).to(:plan).as(:name) }
  it { is_expected.to delegate_method(:plan_ident).to(:plan).as(:ident) }
  it { is_expected.to delegate_method(:category_combo?).to(:category).as(:combo?) }
  it { is_expected.to delegate_method(:coverage_features).to(:category) }

  # Instance Methods -------------------------------------------------------------------------------

  it "defaults to the customer as insurance_holder" do
    expect(Product.new.insurance_holder).to eq("customer")
  end

  describe "#finish_opportunity", :integration do
    let(:opportunity) { create(:opportunity_with_offer) }
    let(:product) { opportunity.offer.offered_products.first }
    let(:document) { create(:document, :advisory_documentation, documentable: product) }

    before do
      opportunity.offer.accept(product)
      document
    end

    it "sends out the advisory_documentation_available mail" do
      expect(ProductMailer).to receive(:advisory_documentation_available).with(product).and_return(ActionMailer::Base::NullMail.new)

      product.send(:finish_opportunity)
    end
  end

  context "net and gross premium" do
    let(:cents) { 1 + (rand * 1000).round }
    let(:insurance_tax) { rand }
    let(:plan) { create(:plan, insurance_tax: insurance_tax) }
    let(:product) { create(:product, category: category, premium_price_cents: cents, plan: plan) }
    let(:category) { create(:category, tax_rate: 19.0) }

    it "should return a calculated net, if insurance tax and the gross premium is given" do
      category.update_attributes!(premium_type: "gross")
      net = product.net_premium_price
      expect(net).to eq(Money.new((cents / (1 + insurance_tax)).round, "EUR"))
    end

    it "should return an unmodified net, if insurance tax and the net premium is given" do
      category.update_attributes!(premium_type: "net")
      net = product.net_premium_price
      expect(net).to eq(Money.new(cents, "EUR"))
    end

    it "should keep the currency, if the net is asked" do
      category.update_attributes!(premium_type: "gross")
      product.update_attributes!(premium_price_currency: "USD")
      net = product.net_premium_price
      expect(net.currency).to eq(Money::Currency.new("USD"))
    end

    # @TODO: https://clarkteam.atlassian.net/browse/JCLARK-25049
    # it "should fail by asking the net premium, if the insurance tax is not set" do
    #   plan.update_attributes!(insurance_tax: nil)
    #   expect {
    #     product.net_premium_price
    #   }.to raise_error("Cannot calculate the net premium, if the insurance tax is not set!")
    # end
    it "should use 0% by asking the net premium, if the insurance tax is not set" do
      plan.update_attributes!(insurance_tax: nil)
      category.update_attributes!(tax_rate: nil)
      net = product.net_premium_price
      expect(net.currency).to eq(Money::Currency.new("EUR"))
      expect(net).to eq(Money.new((cents / (1 + 0)).round, "EUR"))
    end

    it "should get tax_rate from category if insurance_tax is nil" do
      plan.update_attributes!(insurance_tax: nil)
      net = product.net_premium_price
      expect(net.currency).to eq(Money::Currency.new("EUR"))
      expect(net).to eq(Money.new((cents / (1 + (category.tax_rate / 100))).round, "EUR"))
    end

    it "should return a calculated gross, if insurance tax and the net premium is given" do
      category.update_attributes!(premium_type: "net")
      gross = product.gross_premium_price
      expect(gross).to eq(Money.new((cents * (1 + insurance_tax)).round, "EUR"))
    end

    it "should return an unmodified gross, if insurance tax and the gross premium is given" do
      category.update_attributes!(premium_type: "gross")
      gross = product.gross_premium_price
      expect(gross).to eq(Money.new(cents, "EUR"))
    end

    it "should keep the currency, if the gross is asked" do
      category.update_attributes!(premium_type: "net")
      product.update_attributes!(premium_price_currency: "USD")
      gross = product.gross_premium_price
      expect(gross.currency).to eq(Money::Currency.new("USD"))
    end

    it "should default to 0% by asking the gross premium, if the insurance tax is not set" do
      plan.update_attributes!(insurance_tax: nil)
      expect {
        product.gross_premium_price
      }.not_to raise_error
    end
  end

  context "documents" do
    subject { product }
    let(:product) { create(:product, inquiry: create(:inquiry)) }

    it "should know, if there is no cover note" do
      expect(product.has_cover_note?).to be_falsey
    end

    it "should know, if it has a cover note" do
      create(:document, document_type: DocumentType.deckungsnote, documentable: product)
      expect(product.has_cover_note?).to be_truthy
    end

    it "should know, if there is no advisory documentation" do
      expect(product.has_advisory_documentation?).to be_falsey
    end

    it "should know, if it has an advisory documentation" do
      create(:document, document_type: DocumentType.advisory_documentation, documentable: product)
      expect(product.has_advisory_documentation?).to be_truthy
    end
  end

  context "#can_be_canceled_by_customer" do
    it "returns true only for products that are under management, sold by us" do
      product.state = :under_management
      product.sold_by = Product::SOLD_BY_US
      expect(product.can_be_canceled_by_customer?).to eq(true)
    end

    it "returns false if a product is not sold by us" do
      product.state = :under_management
      product.sold_by = Product::SOLD_BY_OTHERS
      expect(product.can_be_canceled_by_customer?).to eq(false)
    end

    it "returns false if a product is not under management" do
      product.state = :ordered
      product.sold_by = Product::SOLD_BY_US
      expect(product.can_be_canceled_by_customer?).to eq(false)
    end
  end

  context "#does_not_belong_to_revenue_pool" do
    let(:subcompany_pool) { create(:subcompany, pools: ["fond_finanz"]) }
    let(:plan_pool) { create(:plan, subcompany: subcompany_pool) }
    let(:product_pool) { create(:product, plan: plan_pool) }

    let(:subcompany_no_pool) { create(:subcompany, pools: []) }
    let(:plan_no_pool) { create(:plan, subcompany: subcompany_no_pool) }
    let(:product_no_pool) { create(:product, plan: plan_no_pool) }

    let(:product) { create(:product) }

    it { expect(product_pool.present_in_pool?).to eq(true) }
    it { expect(product_no_pool.present_in_pool?).to eq(false) }
    it { expect(product.present_in_pool?).to eq(false) }
  end

  context "contact_email" do
    let(:existing_product) { create(:product) }
    it "returns subcompany info email if exists" do
      subcompany = existing_product.subcompany
      subcompany_email = "info@subcompany.com"
      subcompany.info_email = subcompany_email
      expect(existing_product.contact_email).to eq(subcompany_email)
    end

    it "returns subcompany info email if exists and neglect company info email" do
      subcompany = existing_product.subcompany
      company = existing_product.company
      subcompany_email = "info@subcompany.com"
      company_email = "info@company.com"
      subcompany.info_email = subcompany_email
      company.info_email = company_email
      expect(existing_product.contact_email).to eq(subcompany_email)
    end

    it "returns company info email if subcompany info email does not exist" do
      subcompany = existing_product.subcompany
      company = existing_product.company
      subcompany_email = ""
      company_email = "info@company.com"
      subcompany.info_email = subcompany_email
      company.info_email = company_email
      expect(existing_product.contact_email).to eq(company_email)
    end
  end

  context "contact_phone_number" do
    let(:existing_product) { create(:product) }
    it "returns subcompany info phone if exists" do
      subcompany = existing_product.subcompany
      subcompany_phone = "123456789"
      subcompany.info_phone = subcompany_phone
      expect(existing_product.contact_phone_number).to eq(subcompany_phone)
    end

    it "returns subcompany info email if exists and neglect company info email" do
      subcompany = existing_product.subcompany
      company = existing_product.company
      subcompany_phone = "123456789"
      company_phone = "987654321"
      subcompany.info_phone = subcompany_phone
      company.info_phone = company_phone
      expect(existing_product.contact_phone_number).to eq(subcompany_phone)
    end

    it "returns company info email if subcompany info email does not exist" do
      subcompany = existing_product.subcompany
      company = existing_product.company
      subcompany_phone = ""
      company_phone = "987654321"
      subcompany.info_phone = subcompany_phone
      company.info_phone = company_phone
      expect(existing_product.contact_phone_number).to eq(company_phone)
    end
  end

  describe "#annual_maturity=" do
    context "when value is a hash" do
      it do
        subject.annual_maturity = { day: 10, month: 9 }
        expect(subject.annual_maturity).to eq(day: 10, month: 9)
      end
    end

    context "when value is a hash and has string keys" do
      it do
        subject.annual_maturity = { "day" => 10, "month" => 9 }
        expect(subject.annual_maturity).to eq(day: 10, month: 9)
      end
    end

    context "when value is a String" do
      it do
        subject.annual_maturity = "9-10"
        expect(subject.annual_maturity).to eq(day: 10, month: 9)
      end
    end
  end

  describe "annual_maturity_is_not_empty?" do
    context "when annual_maturity is not empty" do
      it do
        subject.annual_maturity = { "day" => 10, "month" => 9 }
        expect(subject.annual_maturity_is_set?).to be(true)
      end
    end

    context "when annual_maturity is empty" do
      it do
        subject.annual_maturity = nil
        expect(subject.annual_maturity_is_set?).to be(false)
      end
    end
  end
  # Class Methods

  context "factory methods" do
    let(:active_coverage) { build(:coverage_feature, :active) }
    let(:inactive_coverage) { build(:coverage_feature, :inactive) }
    let(:category) { create(:category, coverage_features: [active_coverage, inactive_coverage]) }
    let(:coverages) do
      category.coverage_features.each_with_object({}) do |cf, result|
        result[cf.identifier] = ValueTypes::Text.new("Text #{cf.identifier}")
      end
    end

    let(:plan) do
      create(:plan,
             coverages: coverages,
             category: category,
             premium_price_cents: 12_345,
             premium_price_currency: "EUR",
             premium_period: "month")
    end

    let(:offered_product) { Product.create_offered_product!(plan) }

    it "creates a product to be offered" do
      expect(offered_product).to be_a(Product)
    end

    it "creates a product with the default offered product attributes" do
      expect(offered_product.attributes.symbolize_keys).to include(Product.default_offer_attributes.except(:coverages))
    end

    it "should know the plan" do
      expect(offered_product.plan).to eq(plan)
    end

    it "creates a product containing the plan's active coverages" do
      expect(plan.coverages).not_to be_empty
      expect(offered_product.coverages[inactive_coverage.identifier]).to be(nil)
    end

    it "creates a product with the according price information of the plan" do
      expect(offered_product.premium_price).to eq(plan.premium_price)
      expect(offered_product.premium_period).to eq(plan.premium_period)
    end

    it "returns a persisted product" do
      expect(offered_product).to be_persisted
    end

    context "errors" do
      it "should fail for a deactivated plan" do
        plan.deactivate
        expect {
          offered_product
        }.to raise_error("Plan '#{plan.ident}' is deactivated!")
      end
    end
  end

  describe "#periodic_premium?" do
    subject(:product) { described_class.new premium_period: premium_period }

    context "when premium period is month" do
      let(:premium_period) { "month" }

      it { is_expected.to be_periodic_premium }
    end

    context "when premium period is quarter" do
      let(:premium_period) { "quarter" }

      it { is_expected.to be_periodic_premium }
    end

    context "when premium period is year" do
      let(:premium_period) { "year" }

      it { is_expected.to be_periodic_premium }
    end

    context "when premium period is half_year" do
      let(:premium_period) { "half_year" }

      it { is_expected.to be_periodic_premium }
    end

    context "when premium period is once" do
      let(:premium_period) { "once" }

      it { is_expected.not_to be_periodic_premium }
    end

    context "when premium period is none" do
      let(:premium_period) { "none" }

      it { is_expected.not_to be_periodic_premium }
    end
  end
end
