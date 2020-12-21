# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::Rules::GkvAdviceRule do
  let(:sample_coverage_feature_id) { "boolean_247srvctlfn_4d2186" }
  let(:mandate) do
    instance_double(Mandate, revoked?: false,
                             gender:   "female",
                             email:    "test@clark.de")
  end
  let(:category_gkv) { instance_double(Category) }
  let(:whitelist_product) do
    instance_double(
      Product,
      active?:    true,
      category:   category_gkv,
      advised?:   false,
      sold_by_others?: true,
      created_at: 1.hours.ago,
      mandate:    mandate,
      coverages:  { sample_coverage_feature_id => ValueTypes::Boolean::TRUE }
    )
  end
  let(:unlisted_product) do
    instance_double(
      Product,
      active?:    true,
      category:   category_gkv,
      advised?:   false,
      sold_by_others?: true,
      created_at: 1.hours.ago,
      mandate:    mandate,
      coverages:  { sample_coverage_feature_id => ValueTypes::Boolean::TRUE }
    )
  end

  before do
    allow(Category).to receive(:gkv).and_return(category_gkv)
  end

  context "applicability" do
    let(:subject) { Sales::Rules::GkvAdviceRule.new(product: unlisted_product) }

    before do
      allow(unlisted_product).to receive(:created_at).and_return(1.hour.ago)
    end

    it "should be applicable, if it is active" do
      allow(unlisted_product).to receive(:active?).and_return(true)
      expect(subject).to be_applicable
    end

    it "should not be applicable, if it is inactive" do
      allow(unlisted_product).to receive(:active?).and_return(false)
      expect(subject).not_to be_applicable
    end

    it "should be applicable if there is no advice yet" do
      allow(unlisted_product).to receive(:advices).and_return([])
      expect(subject).to be_applicable
    end

    it "should not be applicable if there is an advice" do
      allow(unlisted_product).to receive(:advised?).and_return(true)
      expect(subject).not_to be_applicable
    end

    it "should be applicable, if it is not sold by us" do
      allow(unlisted_product).to receive(:sold_by_others?).and_return(true)
      expect(subject).to be_applicable
    end

    it "should not be applicbale, if it is sold by us" do
      allow(unlisted_product).to receive(:sold_by_others?).and_return(false)
      expect(subject).not_to be_applicable
    end

    it "should be applicable, if the category is GKV" do
      expect(subject).to be_applicable
    end

    it "should not be applicable for other categories" do
      allow(unlisted_product).to receive(:category).and_return(FactoryBot.build(:category))
      expect(subject).not_to be_applicable
    end

    it "should be applicable, if the mandate is not revoked" do
      allow(mandate).to receive(:revoked?).and_return(false)
      expect(subject).to be_applicable
    end

    it "should not be applicable, if the mandate is revoked" do
      allow(mandate).to receive(:revoked?).and_return(true)
      expect(subject).not_to be_applicable
    end

    it "should not be applicable, if the product is younger than 1 hour" do
      allow(unlisted_product).to receive(:created_at).and_return(DateTime.current)
      expect(subject).not_to be_applicable
    end

    it "should not be applicable, if it is not possible to approach the customer via email" do
      allow(mandate).to receive(:email).and_return("")
      expect(subject).not_to be_applicable
    end

    it "should not yield on application, if not applicable" do
      create(:advice_admin)

      allow(mandate).to receive(:email).and_return("") # make it not applicable somehow

      advice = nil
      subject.on_application do |created_advice|
        advice = created_advice
      end

      expect(advice).to be_nil
    end
  end

  context "whitelist missing company" do
    let(:subject) { Sales::Rules::GkvAdviceRule.new(product: unlisted_product) }
    let(:company) { instance_double(Company) }
    let(:gkv_premium) { :national_health_insurance_premium_percentage }
    let(:ident) { "rule" }

    before do
      allow(unlisted_product).to receive(:company).and_return(company)
      allow(unlisted_product).to receive(gkv_premium).and_return(1.0)
      allow(company).to receive(:ident).and_return(ident)
      allow(company).to receive(:gkv_whitelisted?).and_return(false)
    end

    it "should not yield on application, if not applicable" do
      create(:advice_admin)

      advice = nil
      expect {
        subject.on_application do |created_advice|
          advice = created_advice
        end
      }.to raise_error(StandardError, "GKV AUTOMATION Company not whitelisted: rule")

      expect(advice).to be_nil
    end
  end

  context "when gkv_premium is nil" do
    let(:subject) { Sales::Rules::GkvAdviceRule.new(product: unlisted_product) }
    let(:company) { instance_double(Company) }
    let(:gkv_premium) { :national_health_insurance_premium_percentage }
    let(:ident) { "rule" }

    before do
      allow(unlisted_product).to receive(:company).and_return(company)
      allow(unlisted_product).to receive(gkv_premium).and_return(nil)
      allow(company).to receive(:ident).and_return(ident)
      allow(company).to receive(:gkv_whitelisted?).and_return(false)
    end

    it "does not yield on application, if not applicable" do
      create(:advice_admin)

      advice = nil
      expect {
        subject.on_application do |created_advice|
          advice = created_advice
        end
      }.to raise_error(StandardError, "GKV AUTOMATION gkv_premium is nil: rule")

      expect(advice).to be_nil
    end
  end

  context "invalid input" do
    it "should raise an error for nil input" do
      expect {
        Sales::Rules::GkvAdviceRule.new(nil)
      }.to raise_error(ArgumentError)
    end

    it "should raise an error for wrong input" do
      expect {
        Sales::Rules::GkvAdviceRule.new("wrong input")
      }.to raise_error(ArgumentError)
    end
  end

  context "automated advice for TKK" do
    let(:product) { unlisted_product }
    let(:premium) { 1.0 }
    let(:company_ident) { "technfac6e4" }
    let(:whitelisted) { true }

    let(:advice_type) { :create_advice_tkk! }

    it_behaves_like "automated_advice_from_rule"
  end

  context "automated advice for HKK" do
    let(:product) { unlisted_product }
    let(:premium) { 1.0 }
    let(:company_ident) { "handec9db4e" }
    let(:whitelisted) { true }

    let(:advice_type) { :create_advice_hkk! }

    it_behaves_like "automated_advice_from_rule"
  end

  context "automated advice for premium bucket 1" do
    let(:product) { whitelist_product }
    let(:company_ident) { "ident" }
    let(:premium) { 0.3 }
    let(:whitelisted) { true }

    let(:advice_type) { :create_advice_premium_bucket1! }

    it_behaves_like "automated_advice_from_rule"
  end

  context "automated advice for premium bucket 2" do
    let(:product) { whitelist_product }
    let(:premium) { 0.5 }
    let(:company_ident) { "ident" }
    let(:whitelisted) { true }

    let(:advice_type) { :create_advice_premium_bucket2! }

    it_behaves_like "automated_advice_from_rule"
  end

  context "automated advice for premium bucket 3" do
    let(:product) { whitelist_product }
    let(:premium) { 0.8 }
    let(:company_ident) { "ident" }
    let(:whitelisted) { true }

    let(:advice_type) { :create_advice_premium_bucket3! }

    it_behaves_like "automated_advice_from_rule"
  end
end
