# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::OfferAutomations::Plans, :integration do
  let(:admin) { create(:admin, role: create(:role)) }
  let(:coverage_feature) do
    CoverageFeature.new(
      name: "Feature 1",
      definition: "Feat 1 Desc.",
      value_type: "Text",
    )
  end
  let(:coverage_features) { [coverage_feature] }
  let(:coverages) { { coverage_feature.identifier => ValueTypes::Text.new("GKV coverage 1") } }
  let(:category) { create(:category, coverage_features: coverage_features) }
  let(:questionnaire) { create(:questionnaire, category: category) }
  let(:automation) { create(:offer_automation, questionnaire: questionnaire) }
  let(:company1) { create(:company, name: "Company 1") }
  let(:company2) { create(:company, name: "Company 2") }

  describe "when authenticated" do
    before do
      login_as(admin, scope: :admin)
    end

    context "when no plan matches the search term" do
      let(:term) { "no-result-term" }

      before do
        json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/plans?term=#{term}"
      end

      it "returns an empty array" do
        expect(response.status).to eq(200)
        expect(json_response.plans).to eq([])
      end
    end

    context "when any plan matches the search term" do
      let(:term) { "one" }

      it "returns the matching plans" do
        create(:plan, ident: "two", category: category, company: company2)
        plan = create(:plan, ident: "one", category: category, company: company1, coverages: coverages)
        expected = [
          {
            "name" => plan.name,
            "company_name" => company1.name,
            "ident" => plan.ident,
          }
        ]

        json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/plans?term=#{term}"

        expect(response.status).to eq(200)
        expect(json_response.plans).to eq(expected)
      end
    end
  end
end
