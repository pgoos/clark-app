# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for car insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan)       { create :plan, category: category, company: company, subcompany: subcompany }
    let(:product)    { create :product, plan: plan }
    let(:company)    { create :company, ident: "ident" }
    let!(:umbrella)  { create :car_umbrella_category, included_category_ids: [category.id] }
    let!(:category)  { create :category_car_insurance }
    let(:subcompany) { create(:subcompany, revenue_generating: true) }

    context "with company that provides good insurance" do
      let(:company) { create :company, ident: "bavar9f0504" }

      it { is_expected.to eq "101.3" }
    end

    context "with near contract end date" do
      let(:product) { create :product, plan: plan, contract_ended_at: 3.months.from_now }

      it { is_expected.to eq "101.2" }
    end

    context "with no other rule evaluating to true" do
      it { is_expected.to eq "101.1" }
    end
  end
end
