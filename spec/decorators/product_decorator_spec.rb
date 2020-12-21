# frozen_string_literal: true

require "rails_helper"

describe ProductDecorator, type: :decorator do
  subject { product.decorate }

  let(:product) { build_stubbed(:product, plan: plan, number: number) }
  let(:number) { "insurance_number" }

  it { expect(described_class.collection_decorator_class).to eq(ProductCollectionDecorator) }

  describe "#plan" do
    context "when plan is set to nil" do
      let(:plan) { nil }

      it "returns an instance of Plan instead of nil" do
        expect(subject.plan).not_to be_nil
      end
    end

    context "when plan is set" do
      let(:plan) { build_stubbed(:plan) }

      it "returns the plan" do
        expect(subject.plan).to eq(plan)
      end
    end
  end

  describe "#category" do
    context "when plan is set to nil" do
      let(:plan) { nil }

      it "returns an instance of Category instead of nil" do
        expect(subject.category).not_to be_nil
      end
    end

    context "when plan and category are set" do
      let(:plan) { build_stubbed(:plan) }

      it "returns the category's plan" do
        expect(subject.category).to eq(plan.category)
      end
    end
  end

  describe "#company" do
    context "when plan is set to nil" do
      let(:plan) { nil }

      it "returns an instance of Company instead of nil" do
        expect(subject.company).not_to be_nil
      end
    end

    context "when plan and category are set" do
      let(:plan)    { create(:plan, :equity) }
      let(:product) { create(:product, plan: plan) }

      it "returns the company's plan" do
        expect(subject.company).to eq(plan.company)
      end
    end
  end

  describe "#retirement?" do
    let(:plan) { nil }

    context "when category retirement-related" do
      let(:category) { create(:category, ident: "84a5fba0") }

      before { allow(product).to receive(:category).and_return(category) }

      it { expect(subject).to be_retirement }
    end

    context "when category not retirement-related" do
      let(:category) { build_stubbed(:category, ident: "anotherident") }

      it { expect(subject).not_to be_retirement }
    end
  end

  describe "#company_link" do
    context "when company is set" do
      let(:plan)    { create(:plan_gkv) }
      let(:product) { create(:product, plan: plan) }

      it "returns admin_company_path link" do
        link = helper.link_to(plan.company.name, helper.admin_company_path(plan.company))
        expect(subject.company_link).to eq link
      end
    end

    context "when company is nil" do
      let(:plan) { build_stubbed(:plan_gkv) }

      it { expect(subject.company_link).to be_nil }
    end
  end

  describe "#number" do
    let(:plan) { build_stubbed(:plan) }

    context "when number is set" do
      it { expect(subject.number).to eq(number) }
    end

    context "when number is empty" do
      let(:number) { "" }

      it { expect(subject.number).to eq("N/A") }
    end
  end

  describe "#manually_advisable?" do
    before do
      allow_any_instance_of(Domain::Classification::RevenueClassifier).to receive(:non_revenue?).and_return(false)
    end

    let(:product) { create(:product, :sold_by_others) }

    context "when product is sold by others, has no opportunities, and classified as :revenue" do
      it "should return false" do
        expect(subject.sold_by_us?).to be(false)
        expect(subject.opportunities).to be_empty
        expect(subject.manually_advisable?).to be(true)
      end
    end

    context "when product is sold by us" do
      it "should return false" do
        expect(product).to receive(:sold_by_us?).and_return(true)
        expect(subject.manually_advisable?).to be(false)
      end
    end

    context "when opportunities exists" do
      it "should return false" do
        expect(product).to receive(:opportunities).and_return([Object.new])
        expect(subject.manually_advisable?).to be(false)
      end
    end

    context "when product classified :non_renvenue" do
      before do
        allow_any_instance_of(Domain::Classification::RevenueClassifier).to receive(:non_revenue?).and_return(true)
      end

      context "when product category is gkv" do
        it "should return true" do
          expect(product).to receive(:gkv?).and_return(true)
          expect(subject.manually_advisable?).to be(true)
        end
      end

      context "when product category is not gkv" do
        it "should return false" do
          expect(product).to receive(:gkv?).and_return(false)
          expect(subject.manually_advisable?).to be(false)
        end
      end
    end
  end
end
