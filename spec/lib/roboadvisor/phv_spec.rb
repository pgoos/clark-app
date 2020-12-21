# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for phv", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan)       { create :plan, category: category, company: company, subcompany: subcompany }
    let(:company)    { create :company }
    let(:product)    { create :product, :year_premium, plan: plan, premium_price: Money.new(10) }
    let(:category)   { create :category_phv, coverage_features: coverage_features }
    let(:subcompany) { create :subcompany, company: company, pools: %w[quality_pool fonds_finanz] }

    let(:coverage_features) do
      [
        build(:coverage_feature, identifier: "dckngc12f5331a9f374fb", value_type: "Money"),
        build(:coverage_feature, identifier: "dckng7eecd7eff390d702", value_type: "Money")
      ]
    end

    context "with company that provides good insurance" do
      let(:company) { create :company, ident: "bayerc75742" }

      it { is_expected.to eq "2.6.b" }
    end

    context "with sachschaden coverage" do
      # NOTE: should assign coverages after product is created since
      # product model has coverages setter redifined and relying on
      # some database state
      before { product.update(coverages: coverages) }

      context "when value is bigger than 10_000_000" do
        let(:coverages) { {"dckngc12f5331a9f374fb" => {value: "10000001", currency: "EUR"}} }

        it { is_expected.not_to eq "2.1" }
      end

      context "when values is less than 10_000_000" do
        let(:coverages) { {"dckngc12f5331a9f374fb" => {value: "1000000", currency: "EUR"}} }

        it { is_expected.to eq "2.1" }
      end
    end

    context "with vermogensschaden coverage" do
      # NOTE: should assign coverages after product is created since
      # product model has coverages setter redifined and relying on
      # some database state
      before { product.update(coverages: coverages) }

      context "when value is bigger than 10_000_000" do
        let(:coverages) { {"dckng7eecd7eff390d702" => {value: "10000001", currency: "EUR"}} }

        it { is_expected.not_to eq "2.1" }
      end

      context "when values is less than 10_000_000" do
        let(:coverages) { {"dckng7eecd7eff390d702" => {value: "1000000", currency: "EUR"}} }

        it { is_expected.to eq "2.2" }
      end
    end

    context "when premium is bigger or equal to 9_000" do
      let(:product) do
        create :product, :year_premium, plan: plan, premium_price: Money.new(9_000)
      end

      it { is_expected.to eq "2.4" }
    end

    context "when premium is less than 6_000" do
      let(:product) do
        create :product, :year_premium, plan: plan, premium_price: Money.new(1_000)
      end

      it { is_expected.to eq "2.5" }
    end

    context "when premium is less than 100" do
      let(:product) do
        create :product, :year_premium, plan: plan, premium_price: Money.new(10)
      end

      it { is_expected.not_to eq "2.5" }
    end

    context "when company is in good insurances with payment list" do
      let(:company) { create :company, ident: "gotha5a2916" }

      it { is_expected.to eq "2.7" }
    end

    context "when company is COSMOS" do
      let(:company) { create :company, ident: "cosmo0dd227" }

      it { is_expected.to eq "2.13" }
    end

    context "when company is DEBEKA" do
      let(:company) { create :company, ident: "debekb2cabe" }

      it { is_expected.to eq "2.14" }
    end

    context "when company is ASSTEL" do
      let(:company) { create :company, ident: "asste505166" }

      it { is_expected.to eq "2.15" }
    end

    context "when company is WGV" do
      let(:company) { create :company, ident: "wgv47287e5f" }

      it { is_expected.to eq "2.16" }
    end

    context "when company is PROV" do
      let(:company) { create :company, ident: "provib7f8a7" }

      it { is_expected.to eq "2.17" }
    end

    context "when company is HUK" do
      let(:company) { create :company, ident: "hukcoceec6c" }

      it { is_expected.to eq "2.18" }
    end

    context "when company is VGH" do
      let(:company) { create :company, ident: "vghprb1ab7d" }

      it { is_expected.to eq "2.19" }
    end

    context "when product is not in the pools" do
      let(:subcompany) { create :subcompany, company: company, pools: [] }

      it { is_expected.to eq "2.11" }
    end

    context "when no subcompany" do
      let(:subcompany) { nil }

      it { is_expected.to eq "2.11" }
    end

    context "when none of rules apply" do
      it { is_expected.to eq "2.10" }
    end

    context "when coverage is not integer" do
      let(:coverages) { {"dckng7eecd7eff390d702" => {value: "FALSE", currency: "EUR"}} }

      before { product.update(coverages: coverages) }

      it { is_expected.to eq "2.10" }
    end
  end
end
