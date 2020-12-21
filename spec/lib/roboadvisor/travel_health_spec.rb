# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for dental insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan) { create :plan, category: category, company: company }
    let(:product) { create :product, :year_premium, plan: plan, premium_price: premium_price }
    let(:category) { create :category_travel_health }

    context "with company that has yearly_premium_cents <= 4_000" do
      let(:premium_price) { Money.new(3_000, "EUR") }
      let(:company) { create :company }

      it { is_expected.to eq "11.1" }
    end

    context "with company with ident adacv8ee563 that has yearly_premium_cents > 4_000" do
      let(:premium_price) { Money.new(5_000, "EUR") }
      let(:company) { create(:company, ident: "adacv8ee563") }

      it { is_expected.to eq "11.2" }
    end

    context "when no other rule applies" do
      let(:premium_price) { Money.new(5_000, "EUR") }
      let(:company) { create(:company) }

      it { is_expected.to eq "11.3" }
    end
  end
end
