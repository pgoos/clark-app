# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for dental insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan) { create :plan, category: category, company: company }
    let(:product) { create :product, :year_premium, plan: plan, premium_price: premium_price }
    let(:category) { create :category_dental }

    context "with company that has yearly_premium_cents < 40_000" do
      let(:premium_price) { Money.new(30_000, "EUR") }
      let(:company) { create :company }

      it { is_expected.to eq "12.1" }
    end

    context "with company that has yearly_premium_cents >= 40_000 but is improve insurance" do
      let(:premium_price) { Money.new(50_000, "EUR") }
      let(:company) { create(:company, ident: "dfvdec0f5af") }

      it { is_expected.to eq "12.2" }
    end

    context "when no other rule applies" do
      let(:premium_price) { Money.new(50_000, "EUR") }
      let(:company) { create(:company) }

      it { is_expected.to eq "12.3" }
    end
  end
end
