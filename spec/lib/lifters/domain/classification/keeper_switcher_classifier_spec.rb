# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Classification::KeeperSwitcherClassifier do
  let(:classifier) { subject }
  let(:advice) { double(Interaction::Advice) }
  let(:product) { double(Product) }
  let(:quality_classifier) { Domain::Classification::QualityForCustomerClassifier }
  let(:revenue_classifier) { Domain::Classification::RevenueClassifier }
  let(:ks) { "keeper_switcher" }

  before :all do
    #To my knowledge, that should not be necessary, but it is:

  end

  before do
    allow(advice).to receive(:rule_id).and_return("42")
    allow(advice).to receive(:product).and_return(product)
  end

  context "#classify" do
    it "gives a rule id for the quality classifier" do
      expect_any_instance_of(quality_classifier).to receive(:classify).with(advice.rule_id)
      expect_any_instance_of(revenue_classifier).to receive(:classify).and_return(:revenue)

      classifier.classify(advice)
    end

    it "gives a product for the revenue classifier" do
      expect_any_instance_of(quality_classifier).to receive(:classify).and_return(:good)
      expect_any_instance_of(revenue_classifier).to receive(:classify).with(advice.product)

      classifier.classify(advice)
    end
  end

  context "is keeper" do
    it "when makes revenue and is good for the customer" do
      expect_any_instance_of(quality_classifier).to receive(:classify).and_return(:good)
      expect_any_instance_of(revenue_classifier).to receive(:classify).and_return(:revenue)

      expect(classifier.classify(advice)).to eq(:keeper)
    end
  end

  context "is switcher" do
    it "when it does not make revenue" do
      expect_any_instance_of(quality_classifier).to receive(:classify).and_return(:good)
      expect_any_instance_of(revenue_classifier).to receive(:classify).and_return(:non_revenue)
      expect(classifier.classify(advice)).to eq(:switcher)
    end

    it "when it is not good for the customer" do
      expect_any_instance_of(quality_classifier).to receive(:classify).and_return(:bad)
      expect_any_instance_of(revenue_classifier).to receive(:classify).and_return(:revenue)

      expect(classifier.classify(advice)).to eq(:switcher)
    end

    it "when it is not sure it is not good for the customer" do
      expect_any_instance_of(quality_classifier).to receive(:classify).and_return(:unknown)
      expect_any_instance_of(revenue_classifier).to receive(:classify).and_return(:revenue)

      expect(classifier.classify(advice)).to eq(:switcher)
    end
  end

  context "#classify_product" do
    let(:subcompany) { create(:subcompany, revenue_generating: true) }
    let(:product) do
      create(:product, state: "details_available", subcompany: subcompany)
    end

    context "is unknown" do
      it "has no advices" do
        classification = classifier.classify_product(product)
        expect(classification).to eq(:unknown)
      end

      it "has only unknown advices" do
        create(:advice, product: product)

        classification = classifier.classify_product(product)
        expect(classification).to eq(:unknown)
      end
    end

    context "is keeper" do
      it "has a most recent keeper advice" do
        create(:advice, product: product, rule_id: "good")
        create(:advice, product: product, rule_id: "bad")
        create(:advice, product: product, rule_id: "good")
        create(:advice, product: product, rule_id: "unknown")


        classification = classifier.classify_product(product)
        expect(classification).to eq(:keeper)
      end
    end

    context "is switcher" do
      it "the product is non_revenue" do
        product.update(state: "takeover_denied")

        classification = classifier.classify_product(product)
        expect(classification).to eq(:switcher)
      end

      it "has a most recent switcher advice" do
        create(:advice, product: product, rule_id: "bad")
        create(:advice, product: product, rule_id: "good")
        create(:advice, product: product, rule_id: "bad")
        create(:advice, product: product, rule_id: "unknown")


        classification = classifier.classify_product(product)
        expect(classification).to eq(:switcher)
      end
    end
  end

  context "#classify_advised_product" do
    let(:subcompany) { create(:subcompany, revenue_generating: true) }
    let(:product) do
      create(:product, state: "details_available", subcompany: subcompany)
    end

    context "is unknown" do
      it "has no advices" do
        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:unknown)
      end

      it "has advices but they are no keeper_switcher" do
        create(:advice, product: product, rule_id: "good")
        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:unknown)
      end

      it "has only unknown advices" do
        create(:advice, product: product)

        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:unknown)
      end

      it "unknown if it has an offer" do
        create(:advice, product: product, rule_id: "good", identifier: ks)
        create(:advice, product: product, rule_id: "bad", identifier: ks)
        create(:advice, product: product, rule_id: "good", identifier: ks)
        create(:advice, product: product, rule_id: "unknown", identifier: ks)

        create(:opportunity, old_product: product)

        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:unknown)
      end
    end

    context "is keeper" do
      it "has a most recent keeper advice" do
        create(:advice, product: product, rule_id: "good", identifier: ks)
        create(:advice, product: product, rule_id: "bad", identifier: ks)
        create(:advice, product: product, rule_id: "good", identifier: ks)
        create(:advice, product: product, rule_id: "unknown", identifier: ks)


        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:keeper)
      end
    end

    context "is switcher" do
      it "the product is non_revenue" do
        create(:advice, product: product, rule_id: "good", identifier: ks)

        product.update(state: "takeover_denied")

        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:switcher)
      end

      it "has a most recent switcher advice" do
        create(:advice, product: product, rule_id: "bad", identifier: ks)
        create(:advice, product: product, rule_id: "good", identifier: ks)
        create(:advice, product: product, rule_id: "bad", identifier: ks)
        create(:advice, product: product, rule_id: "unknown", identifier: ks)


        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:switcher)
      end
    end
  end
end
