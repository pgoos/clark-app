# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for home insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan)       { create :plan, category: category, company: company, subcompany: subcompany }
    let(:product)    { create :product, :year_premium, plan: plan, premium_price: Money.new(1_000) }
    let(:category)   { create :category_home_insurance }
    let(:company)    { create :company }
    let(:subcompany) { create(:subcompany, revenue_generating: true) }

    context "with contract_ended_at about to expiry" do
      let(:product) { create(:product, plan: plan, contract_ended_at: 1.month.from_now) }

      it { is_expected.to eq "14.2" }
    end

    context "with allianz" do
      let(:company) { create(:company, ident: "allia8c23e2") }

      it { is_expected.to eq "14.3" }
    end

    context "with company in whitelist" do
      let(:company) { create(:company, ident: "grund9f0b8c") }

      it { is_expected.to eq "14.4" }
    end

    context "with none of the other rules evaluating to true" do
      it { is_expected.to eq "14.5" }
    end
  end
end
