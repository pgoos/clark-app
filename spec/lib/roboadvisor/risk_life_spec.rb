# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for risk life insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan)       { create :plan, category: category, company: company }
    let(:company)    { create :company }
    let(:product)    { create :product, plan: plan  }
    let(:subcompany) { create :subcompany, company: company, pools: %w[quality_pool fonds_finanz] }
    let(:category)   { create :category_risk_life }

    context "with company ident among the good companies" do
      let(:company) { create :company, ident: "europ3a06f4" }

      it { is_expected.to eq "16.3" }
    end

    context "when no other rule applies" do
      let(:company) { create :company }

      it { is_expected.to eq "16.4" }
    end
  end
end
