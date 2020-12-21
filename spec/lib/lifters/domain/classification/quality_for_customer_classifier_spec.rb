# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Classification::QualityForCustomerClassifier do
  let(:classifier) { subject }

  context "load classification" do
    before do
      described_class.load_classification
    end

    it "has entries for all robo rules and no more" do
      #Expected 157 rules classified
      #Expected +2 good, bad sample/test classifications
      expect(described_class.quality_for_customer.length).to eq(175)
    end

    it "has only :good, :bad, and unknown" do
      unique_values = described_class.quality_for_customer.values.uniq

      expect(unique_values).to contain_exactly(:good, :bad, :unknown)
    end
  end

  context "is unknown" do
    it "when it has no rule id" do
      expect(classifier.classify(nil)).to eq(:unknown)
    end

    it "when it has blank rule id" do
      expect(classifier.classify("")).to eq(:unknown)
    end

    it "when it is the master chatch all" do
      expect(classifier.classify("0")).to eq(:unknown)
    end
  end

  context "is good" do
    it "when it received a rule that is a positive rule" do
      expect(classifier.classify("1.3")).to eq(:good)
    end
  end

  context "is bad" do
    it "when it is not good, or unknown" do
      expect(classifier.classify("2.1")).to eq(:bad)
    end
  end

  describe "#classify_advised_product" do
    let(:subcompany) { build(:subcompany, revenue_generating: true) }
    let(:subcompany_non_rev) { build(:subcompany, revenue_generating: false) }
    let(:product) do
      build(:product, state: "details_available", subcompany: subcompany)
    end
    let(:product_gkv) do
      build(:product_gkv, state: "details_available", subcompany: subcompany_non_rev)
    end

    context "is unknown" do
      it "has no advices" do
        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:unknown)
      end

      it "has only unknown advices" do
        create(:advice, product: product)

        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:unknown)
      end

      context "the product is non_revenue" do
        let(:product) do
          build(:product, state: "takeover_denied", subcompany: subcompany)
        end

        it do
          classification = classifier.classify_advised_product(product)
          expect(classification).to eq(:unknown)
        end
      end
    end

    context "is good" do
      let(:product_sold) { build(:product, :sold_by_us) }

      it "has a most recent good advice" do
        create(:advice, :keeper, product: product, rule_id: "bad", created_at: 3.minutes.ago)
        create(:advice, :keeper, product: product, rule_id: "unknown", created_at: 2.minutes.ago)
        create(:advice, :keeper, product: product, rule_id: "good", created_at: 1.minute.ago)

        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:good)
      end

      it "has a most recent good advice but is gkv" do
        create(:advice, :keeper, product: product_gkv, rule_id: "good", created_at: 1.minute.ago)

        classification = classifier.classify_advised_product(product_gkv)
        expect(classification).to eq(:good)
      end

      it "was sold by us" do
        classification = classifier.classify_advised_product(product_sold)
        expect(classification).to eq(:good)
      end
    end

    context "is bad" do
      it "has a most recent bad advice" do
        create(:advice, :keeper, product: product, rule_id: "good", created_at: 3.minutes.ago)
        create(:advice, :keeper, product: product, rule_id: "unknown", created_at: 2.minutes.ago)
        create(:advice, :keeper, product: product, rule_id: "bad", created_at: 1.minute.ago)

        classification = classifier.classify_advised_product(product)
        expect(classification).to eq(:bad)
      end
    end

    context "the product has consultant advice" do
      before do
        allow_any_instance_of(Domain::Classification::RevenueClassifier).to receive(:classify).and_return(:revenue)
      end

      context "assesment not given" do
        let(:advice) { create :manual_advice, product: product }

        it "should classify as unknown" do
          classification = classifier.classify_advised_product(advice.product)

          expect(classification).to be(:unknown)
        end
      end

      context "assesment is keeper" do
        let(:advice) { create :manual_advice_keeper, product: product }

        it "should classify as good" do
          classification = classifier.classify_advised_product(advice.product)

          expect(classification).to be(:good)
        end
      end

      context "assesment is switcher" do
        let(:advice) { create :manual_advice_switcher, product: product }

        it "should classify as bad" do
          classification = classifier.classify_advised_product(advice.product)

          expect(classification).to be(:bad)
        end
      end
    end

    context "the product has multiple advices" do
      before do
        allow_any_instance_of(Domain::Classification::RevenueClassifier).to receive(:classify).and_return(:revenue)
      end

      it "should classify by recent advice" do
        create(:manual_advice, product: product, created_at: 10.minutes.ago)

        classification = classifier.classify_advised_product(product)
        expect(classification).to be(:unknown)

        create(:advice, :keeper, product: product, rule_id: "bad", created_at: 8.minutes.ago)

        classification = classifier.classify_advised_product(product)
        expect(classification).to be(:bad)

        create(:manual_advice_keeper, product: product, created_at: 6.minutes.ago)

        classification = classifier.classify_advised_product(product)
        expect(classification).to be(:good)
      end
    end
  end
end
