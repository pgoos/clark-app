# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for private health insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan) { create :plan, category: category, company: company }
    let(:company) { create :company }
    let(:product) { create :product, plan: plan, contract_started_at: 1.year.ago }
    let(:subcompany) { create :subcompany, company: company }
    let(:category) { create :category_pkv }

    context "when contract started more than 5 years ago" do
      let(:product) { create :product, plan: plan, contract_started_at: 6.years.ago }

      it { is_expected.to eq "18.1" }
    end

    context "with company ident among the good companies" do
      let(:company) { create :company, ident: "alteofd4266" }

      it { is_expected.to eq "18.2" }
    end

    context "when no other rule applies" do
      it { is_expected.to eq "18.3" }
    end
  end
end
