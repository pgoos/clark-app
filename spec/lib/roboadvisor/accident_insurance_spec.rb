# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for accident insurance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan)       { create :plan, category: category, company: company, subcompany: subcompany }
    let(:product)    { create :product, :year_premium, plan: plan, premium_price: Money.new(1_000) }
    let(:category)   { create :category_accident_insurace }
    let(:subcompany) { create(:subcompany, revenue_generating: true) }

    context "with company that provides good insurance" do
      let(:company) { create :company, ident: "ammer0658ce" }

      it { is_expected.to eq "5.2" }
    end

    context "without company that provides good insurance" do
      let(:company)  { create :company }

      it { is_expected.to eq "5.3" }
    end
  end
end
