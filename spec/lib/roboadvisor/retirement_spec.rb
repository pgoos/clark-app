# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for retirement insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan) { create :plan, category: category, company: company }
    let(:company) { create :company }
    let(:product) { create :product, plan: plan }
    let(:subcompany) { create :subcompany, company: company }
    let(:category) { create :category_retirement }

    context "with company ident from 4 or 5 star companies" do
      let(:company) { create :company, ident: "altel6bff35" }

      it { is_expected.to eq "29.1" }
    end

    context "with company ident from 3 star companies" do
      let(:company) { create :company, ident: "wwkal03c1f5" }

      it { is_expected.to eq "29.2" }
    end

    context "with company ident from 2 or 1 star companies" do
      let(:company) { create :company, ident: "arag70040d5" }

      context "when contract_started_at before 2011" do
        let(:product) { create :product, plan: plan, contract_started_at: Time.zone.now.change(year: 2010) }

        it { is_expected.to eq "29.3" }
      end

      context "when contract_started_at from or after 2011" do
        let(:product) { create :product, plan: plan, contract_started_at: Time.zone.now.change(year: 2012) }

        it { is_expected.to eq "29.4" }
      end
    end

    context "when no other rule applies" do
      let(:company) { create :company }

      it { is_expected.to eq "29.5" }
    end
  end
end
