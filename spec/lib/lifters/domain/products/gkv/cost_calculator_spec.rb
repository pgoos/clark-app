# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::Gkv::CostCalculator do
  subject { Domain::Products::Gkv::CostCalculator }

  let(:gkv_category) { create(:category_gkv) }
  let(:company) { create(:gkv_company, national_health_insurance_premium_percentage: premium_percentage) }
  let(:plan) { create(:plan, company: company, category: gkv_category) }
  let(:product) { create(:product_gkv, plan: plan) }

  describe "#call" do
    context "when national_health_insurance_premium_percentage is nil" do
      let(:premium_percentage) { nil }

      it "should use national_health_insurance_premium_percentage = 0 to calcualte" do
        expect(subject.call(product)).to eql(calculate_cost(0))
      end
    end

    context "when national_health_insurance_premium_percentage has value" do
      let(:premium_percentage) { 0.9 }

      it "should use (national_health_insurance_premium_percentage / 2) to calcualte" do
        expect(subject.call(product)).to eql(calculate_cost(0.9))
      end
    end
  end

  def calculate_cost(premium_percentage)
    Settings.base_gkv_contribution_percentage.to_f + premium_percentage.to_f / 2.0
  end
end
