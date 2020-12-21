require "rails_helper"

RSpec.describe Sales::Rules::OptimizeGkvRuleTkHkk, :integration do
  let(:sample_coverage_feature_id) { "boolean_247srvctlfn_4d2186" }

  let(:mandate) { create(:mandate, state: "accepted", gender: "female") }

  let(:product_stubbing) { {mandate: mandate, created_at: 1.hour.ago, advised?: true} }

  let(:coverages) { {sample_coverage_feature_id => ValueTypes::Boolean::TRUE} }

  let(:whitelist_product) { instance_double(Product, product_stubbing) }
  let(:unlisted_product) { instance_double(Product, product_stubbing) }

  context "product" do
    before do
      allow(whitelist_product).to receive_message_chain(:company, :gkv_whitelisted?).and_return(true)
      allow(unlisted_product).to receive_message_chain(:company, :gkv_whitelisted?).and_return(false)
    end

    it "is processable when whitelisted with gender" do
      subject = Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: whitelist_product)
      expect(subject.applicable?).to be_truthy
    end

    it "is not processable when unlisted" do
      subject = Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: unlisted_product)
      expect(subject.applicable?).to be_falsey
    end

    it "is not processable if mandate has no gender" do
      mandate.update_attributes(gender: nil)
      subject = Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: whitelist_product)
      expect(subject.applicable?).to be_falsey
    end
  end

  context "#on_application" do
    let(:tk_subcompany) { create(:subcompany_gkv, name: "Techniker Krankenkasse", ident: "technfac6e4") }
    let!(:tk_plan) do
      create(:plan, subcompany: tk_subcompany, coverages: {sample_coverage_feature_id => ValueTypes::Boolean::TRUE})
    end
    let(:hkk_subcompany) { create(:subcompany_gkv, name: "Handelskrankenkasse (hkk)", ident: "handec9db4e") }
    let!(:hkk_plan) do
      create(:plan, subcompany: hkk_subcompany, coverages: {sample_coverage_feature_id => ValueTypes::Boolean::TRUE})
    end

    let(:advices) { create_list(:advice, 1) }
    let(:company) { create(:company, gkv_whitelisted: true) }
    let(:plan) { create(:plan, company: company) }
    let(:old_product) { create(:product, advices: advices, plan: plan, created_at: 1.day.ago) }

    before do
      create(:plan,
             subcompany: hkk_subcompany,
             coverages: { sample_coverage_feature_id => ValueTypes::Boolean::TRUE },
             state: "inactive")
    end

    it "creates the correct products" do
      subject = described_class.new(old_product: old_product)

      block_visited = false

      subject.on_application do |top_cover_offer, top_price_offer, old_offer|
        block_visited = true

        top_cover_product = top_cover_offer.product
        top_price_product = top_price_offer.product

        expect(top_cover_product.sold_by_us?).to eq true
        expect(top_cover_product.plan).to eq tk_plan
        expect(top_cover_offer.recommended).to eq true

        expect(top_price_product.sold_by_us?).to eq true
        expect(top_price_product.plan).to eq hkk_plan
        expect(top_price_offer.recommended).to be_nil

        expect(old_offer.product).to eq old_product
        expect(old_offer.write_protected).to eq true
      end

      expect(block_visited).to eq true
    end
  end

  context "invalid input" do
    it "is not applicable for an empty input" do
      subject = Sales::Rules::OptimizeGkvRuleTkHkk.new({})
      expect(subject.applicable?).to be_falsey
    end

    it "is not applicable for an nil input" do
      expect {
        Sales::Rules::OptimizeGkvRuleTkHkk.new(nil)
      }.to raise_error(ArgumentError, "The rule input is required to be a hash!")
    end

    it "is not instantiatable for an input not being a Hash" do
      expect {
        Sales::Rules::OptimizeGkvRuleTkHkk.new("wrong input type")
      }.to raise_error(ArgumentError, "The rule input is required to be a hash!")
    end

    it "is not applicable for a product not being a product" do
      subject = Sales::Rules::OptimizeGkvRuleTkHkk.new(old_product: "wrong input type")
      expect(subject.applicable?).to be_falsey
    end
  end
end
