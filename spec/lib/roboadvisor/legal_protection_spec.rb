# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for legal protection", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan)       { create :plan, category: category, company: company, subcompany: subcompany }
    let(:company)    { create :company }
    let(:product)    { create :product, :year_premium, plan: plan, premium_price: Money.new(1_000) }
    let(:subcompany) { create :subcompany, company: company, pools: %w[quality_pool fonds_finanz] }
    let(:category)   { create :category_legal }

    context "with company ident arag70040d5" do
      let(:company) { create :company, ident: "arag70040d5" }

      it { is_expected.to eq "3.1" }
    end

    context "with company ident das9a42a4d2 or rolanc8aa07" do
      let(:company) { create :company, ident: "das9a42a4d2" }

      it { is_expected.to eq "3.2" }
    end

    context "with company ident rolanc8aa07" do
      let(:company) { create :company, ident: "rolanc8aa07" }

      it { is_expected.to eq "3.2" }
    end

    context "with company ident devk0584d87" do
      let(:company) { create :company, ident: "devk0584d87" }

      it { is_expected.to eq "3.3" }
    end

    context "with company ident deura71ed9b" do
      let(:company) { create :company, ident: "deura71ed9b" }

      it { is_expected.to eq "3.6" }
    end

    context "with company ident allref35893" do
      let(:company) { create :company, ident: "allref35893" }

      it { is_expected.to eq "3.7" }
    end

    context "with yearly premium is equal or grater than 1 EURO but less than 250 EURO" do
      before { product.update(premium_period: "year", premium_price: 10) }

      it { is_expected.to eq "3.8" }
    end

    context "when no rule apply" do
      before { product.update(premium_period: "year", premium_price: 300) }

      it { is_expected.to eq "3.9" }
    end
  end
end
