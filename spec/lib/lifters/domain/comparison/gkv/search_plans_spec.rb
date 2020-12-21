# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Comparison::GKV::SearchPlans do
  let(:gkv_category) { create(:category_gkv) }
  let(:gkv_company) do
    create(
      :gkv_company,
      gkv_whitelisted: true,
      national_health_insurance_premium_percentage: 1.5
    )
  end
  let(:sample_coverage_feature_id) { "boolean_247srvctlfn_4d2186" }

  it "shoudld return empty when plans list is empty" do
    plans = subject.plans_with_coverages
    expect(plans.count).to be(0)
  end

  context "with gkv plans" do
    it "should return one plan for gkv" do
      create(
        :plan,
        coverages: {sample_coverage_feature_id => ValueTypes::Boolean::TRUE},
        company:   gkv_company,
        category:  gkv_category
      )
      plans = subject.plans_with_coverages
      expect(plans.count).to be(1)
    end

    it "should return no plan for gkv" do
      create(
        :plan_gkv,
        company:  gkv_company,
        category: gkv_category
      )
      plans = subject.plans_with_coverages
      expect(plans.count).to be(0)
    end

    it "should return all plans for gkv" do
      2.times do |i|
        create(
          :plan_gkv,
          category:  gkv_category
        )
      end
      plans = subject.all_plans
      expect(plans.count).to be(2)
    end
  end
end
