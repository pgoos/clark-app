# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for riester insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan) { create :plan, category: category, company: company }
    let(:product) { create :product, :year_premium, plan: plan, premium_price: premium_price }
    let(:category) { create :category_riester }
    let(:company) { create :company }

    context "with yearly_premium_cents > 10_000" do
      let(:premium_price) { Money.new(11_000, "EUR") }

      it { is_expected.to eq "107.1" }
    end

    context "catch all" do
      let(:premium_price) { Money.new(10_000, "EUR") }

      it { is_expected.to eq "107.2" }
    end
  end
end
