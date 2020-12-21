# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for household", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan)     { create :plan, category: category, company: company }
    let(:company)  { create :company }
    let(:product)  { create :product, :year_premium, plan: plan }
    let(:category) { create :category_hr }

    context "good insurance with company ident haftpe6e5c1 or ammer0658ce" do
      let(:company) { create :company, ident: "haftpe6e5c1" }

      it { is_expected.to eq "4.1" }
    end

    context "when contract_ended_at is more than 12 months and not special company" do
      before { product.update_attribute(:contract_ended_at, 13.months.from_now) }

      it { is_expected.to eq "4.2" }
    end

    context "when contract_started_at more than 3 years ago and not special company" do
      before { product.update_attribute(:contract_started_at, 4.years.ago) }

      it { is_expected.to eq "4.3" }
    end

    context "with company ident asste505166" do
      let(:company) { create :company, ident: "asste505166" }

      it { is_expected.to eq "4.8" }
    end

    context "good insurance with company ident hukcoceec6c or huk2466e28b" do
      let(:company) { create :company, ident: "hukcoceec6c" }

      it { is_expected.to eq "4.9" }
    end

    context "good insurance with company ident gener339e31" do
      let(:company) { create :company, ident: "gener339e31" }

      it { is_expected.to eq "4.10" }
    end

    context "when no rule apply" do
      before { product.update_attribute(:contract_started_at, 1.year.ago) }

      it { is_expected.to eq "4.7" }
    end
  end
end
