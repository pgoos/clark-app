# frozen_string_literal: true

require "swagger_helper"

describe ::Offers::Api::Admin::V2::CoverageFeatures, :integration, type: :request, swagger_doc: "v2/admin.yaml" do
  let("Content-Type".to_sym) { "application/json" }
  let(:accept) { "application/vnd.clark-admin-v2+json" }
  let(:category) { create(:category_gkv) }
  let(:admin) { create(:admin) }

  path "/api/admin/offers/categories/{category_ident}/coverage_features" do
    get "Get opportunity details" do
      consumes "application/json"
      parameter name: :category_ident, in: :path, schema: { type: :string }, description: "Category ident"
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: { type: :string }

      response "401", "without authentication" do
        let(:category_ident) { category.ident }
        run_test!
      end

      response "401", "for non existing opportunity" do
        let(:category_ident) { 1111 }
        run_test!
      end

      response "200", "for existing opportunity" do
        let(:category_ident) { category.ident }

        before { login_as(admin, scope: :admin) }

        run_test! do |_response|
          coverages = json_response[:data]
          expect(coverages.first["type"]).to eq "coverage_feature"
          expect(coverages.first["attributes"].keys).to include("ident", "name", "value_type")
        end
      end
    end
  end
end
