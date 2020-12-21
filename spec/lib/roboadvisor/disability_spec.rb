# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for disability insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan)       { create :plan, category: category, company: company, subcompany: subcompany }
    let(:category)   { create :bu_category, coverage_features: coverage_features }
    let(:company)    { create :company }
    let(:subcompany) { create(:subcompany, revenue_generating: true) }
    let(:product) do
      create :product, :year_premium, plan: plan, premium_price: Money.new(1_000), coverages: coverages
    end
    let(:coverage_features) do
      [
        build(:coverage_feature, identifier: "mntlcfda086f6f09f928d", value_type: "Money")
      ]
    end
    let(:coverages) { {"mntlcfda086f6f09f928d" => {value: "1001", currency: "EUR"}} }

    context "with coverage mntlcfda086f6f09f928d less than 1000" do
      let(:coverages) { {"mntlcfda086f6f09f928d" => {value: "999", currency: "EUR"}} }

      it { is_expected.to eq "7.1" }
    end

    context "with company in whitelist" do
      let(:company) { create(:company, ident: "swiss394b52") }

      it { is_expected.to eq "7.2" }
    end

    context "with company ident nrnbe80515b - Nuernberger Versicherungsgruppe" do
      let(:company) { create(:company, ident: "nrnbe80515b") }

      it { is_expected.to eq "7.3" }
    end

    context "with none of the other rules evaluating to true" do
      it { is_expected.to eq "7.4" }
    end
  end
end
