# frozen_string_literal: true

require "swagger_helper"

describe ::Offers::Api::Admin::V2::Plans, type: :request, integration: true, swagger_doc: "v2/admin.yaml" do
  let("Content-Type".to_sym) { "application/json" }
  let(:accept) { "application/vnd.clark-admin-v2+json" }

  let(:document1) { create(:document) }
  let(:document2) { create(:document) }

  let(:parent_plan) { create(:parent_plan, documents: [document1, document2]) }
  let!(:plan) { create(:plan, :activated, :with_stubbed_coverages, parent_plan: parent_plan) }

  let(:admin) { create(:admin) }

  path "/api/admin/offers/manual_creation/plans" do
    get "Get plans" do
      consumes "application/json"
      parameter name: :category_ident, in: :query, type: :string, description: "Contract ID"
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: { type: :string }

      response "401", "without authorization" do
        let(:category_ident) { plan.category.ident }
        run_test!
      end

      response "404", "non-existing contract" do
        let!(:category_ident) { "fake-ident" }
        let!(:authentication) { login_as(admin, scope: :admin) }
        run_test!
      end

      response "200", "show contract" do
        let(:category_ident) { plan.category.ident }
        let!(:authentication) { login_as(admin, scope: :admin) }
        run_test! do |_response|
          expect(response.status).to eq 200
          expect(json_response["data"]).to be_kind_of Array
          expect(json_response["data"].first["id"]).to be nil
          expect(json_response["data"].first["type"]).to eq "plan"
          expect(json_response["data"].first["attributes"]["ident"]).to eq plan.ident
          expect(json_response["data"].first["attributes"]["name"]).to eq plan.name
          expect(json_response["data"].first["attributes"]["companyName"]).to eq plan.company_name
        end
      end
    end
  end

  path "/api/admin/offers/manual_creation/plans/{ident}" do
    get "Get plan with details" do
      consumes "application/json"
      parameter name: :ident, in: :path, type: :string, description: "Contract ID"
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: { type: :string }

      response "401", "without authorization" do
        let(:ident) { plan.ident }

        run_test!
      end

      response "404", "non-existing ident" do
        let!(:ident) { "fake-ident" }
        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test!
      end

      response "200", "show plan" do
        let(:ident) { plan.ident }
        let!(:authentication) { login_as(admin, scope: :admin) }

        run_test! do |_response|
          expect(response.status).to eq 200
          expect(json_response["data"]).to be_kind_of Hash
          expect(json_response["data"]["id"]).to be nil
          expect(json_response["data"]["type"]).to eq "plan_with_details"
          expect(json_response["data"]["attributes"]["ident"]).to eq plan.ident
          expect(json_response["data"]["attributes"]["name"]).to eq plan.name
          expect(json_response["data"]["attributes"]["premium_price_cents"]).to eq plan.premium_price_cents
          expect(json_response["data"]["attributes"]["premium_price_currency"]).to eq plan.premium_price_currency
          expect(json_response["data"]["attributes"]["premium_period"]).to eq plan.premium_period
          expect(json_response["data"]["attributes"]["coverages"].size).to eq plan.coverages.size
          expect(json_response["data"]["attributes"]["documents"].size).to eq parent_plan.documents.size
        end
      end
    end
  end
end
