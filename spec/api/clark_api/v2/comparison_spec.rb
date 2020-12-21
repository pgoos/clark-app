# frozen_string_literal: true

require "rails_helper"

# FIXME: UNSKIP TESTS https://clarkteam.atlassian.net/browse/JCLARK-21643
RSpec.describe ClarkAPI::V2::Comparison, skip: true do
  let(:user) { create(:user, mandate: create(:mandate)) }
  let(:sample_coverage_feature_id) { "boolean_247srvctlfn_4d2186" }
  let!(:gkv_company) do
    create(
      :gkv_company, gkv_whitelisted: true, national_health_insurance_premium_percentage: 1.5
    )
  end

  let(:coverage)  { {sample_coverage_feature_id => ValueTypes::Boolean::TRUE} }
  let!(:gkv_plan) { create(:plan_gkv, coverages: [coverage], company: gkv_company) }

  context "GET /api/gkv/plans" do
    it "gets the plans for gkv" do
      login_as(user, scope: :user)

      json_post_v2 "/api/comparison/gkv/search"

      expect(response.status).to eq(201)
    end

    it "returns all the entities that are exposed" do
      login_as(user, scope: :user)

      json_post_v2 "/api/comparison/gkv/search"

      expect(response.status).to eq(201)
      expect(json_response.plans[0].id).to be_present
      expect(json_response.plans[0].name).to  be_present
      expect(json_response.plans[0].ident).to be_present
      expect(json_response.plans[0].price).to be_present
      expect(json_response.plans[0].currency).to be_present
      expect(json_response.plans[0].period).to be_present
      expect(json_response.plans[0].coverages).to be_present
      expect(json_response.plans[0].saving).to be_nil
      expect(json_response.plans[0].company).to be_present
      expect(json_response.plans[0].company.id).to be_present
      expect(json_response.plans[0].company.ident).to be_present
      expect(json_response.plans[0].company.name).to be_present
      expect(json_response.plans[0].company.logo).to be_present
    end

    it "gets plans for gkv with correct query params" do
      login_as(user, scope: :user)

      json_post_v2 "/api/comparison/gkv/search", zipcode: "60000", yearly_salary: "123444",
                                                 current_insurance_id: 1

      expect(response.status).to eq(201)
    end

    it "validates if zipcode entered is false" do
      login_as(user, scope: :user)

      json_post_v2 "/api/comparison/gkv/search", zipcode: "-60000", yearly_salary: "123444",
                                                 current_insurance_id: "what is this"

      expect(response.status).to eq(400)
    end
  end

  context "GET /api/gkv/companies" do
    it "gets all the companies for gkv plans" do
      login_as(user, scope: :user)

      json_get_v2 "/api/comparison/gkv/companies"

      expect(response.status).to eq(200)
    end

    it "get companies which have all relevant fields exposed" do
      login_as(user, scope: :user)

      json_get_v2 "/api/comparison/gkv/companies"

      expect(json_response.company[0].id).to be_present
      expect(json_response.company[0].name).to be_present
      expect(json_response.company[0].logo).to be_present
    end
  end
end
