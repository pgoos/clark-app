# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Categories, :integration do
  context "GET /api/categories/:ident/companies" do
    context "company ids for the category plans" do
      let!(:vertical)    { create(:vertical) }
      let!(:company)     { create(:company) }
      let!(:company_two) { create(:company) }
      let!(:company_three) { create(:company) }

      let!(:subcompany_one)   { create(:subcompany, verticals: [vertical], company: company) }
      let!(:subcompany_two)   { create(:subcompany, verticals: [vertical], company: company) }
      let!(:subcompany_three) { create(:subcompany, verticals: [vertical], company: company_two) }

      let!(:category) { create(:category, vertical: vertical) }

      it "returns company IDs from the API" do
        json_get_v2 "/api/categories/#{category.ident}/companies"
        expect(response.status).to eq(200)
        expect(json_response.companies.size).to eq(2)
        expect(json_response.companies).to include(company.id, company_two.id)
      end
    end
  end

  context "GET /api/categories/ident/:ident" do
    context "category that can be found" do
      let(:category) { create(:category, starting_price_cents: 500, margin_level: "medium") }
      let(:category_gkv) { create(:category_gkv, margin_level: "high") }

      it "returns the correct category from the API" do
        json_get_v2 "/api/categories/ident/#{category.ident}"

        expect(response.status).to eq(200)
        expect(json_response.name).to eq(category.name)
        expect(json_response.ident).to eq(category.ident)

        expect(json_response.starting_price).to eq(
          "currency" => "EUR",
          "value" => 500
        )

        expect(json_response.margin_level).to eq(category.margin_level)
      end

      it "returns the correct GKV category from the API" do
        json_get_v2 "/api/categories/ident/#{category_gkv.ident}"

        expect(response.status).to eq(200)
        expect(json_response.name).to eq(category_gkv.name)
        expect(json_response.ident).to eq(category_gkv.ident)
        expect(json_response).not_to have_key("margin_level")
      end
    end

    context "category that does not exist" do
      before do
        json_get_v2 "/api/categories/ident/somethingThatDoesNotExist"
      end

      it "returns a 404 not found" do
        expect(response.status).to eq(404)
      end
    end
  end

  # This API endpoint is deprecated. Categories ought to be identified via idents only.
  context "GET /api/categories/:id" do
    let!(:category) { create(:category, margin_level: "high") }

    before do
      json_get_v2 "/api/categories/#{category.id}"
    end

    it "returns the correct category from the API" do
      expect(response.status).to eq(200)
      expect(json_response.id).to eq(category.id)
      expect(json_response.name).to eq(category.name)
      expect(json_response.ident).to eq(category.ident)
      expect(json_response.margin_level).to eq(category.margin_level)
    end
  end

  context "GET /api/categories/for_request_offer" do
    let!(:questionnaire_one) { create(:questionnaire) }
    let!(:questionnaire_two) { create(:questionnaire) }

    let!(:category_one) {
      create(:category, questionnaire: questionnaire_one, available_for_offer_request: true, search_tokens: "hello")
    }
    let!(:category_two)   { create(:category, questionnaire: questionnaire_two, available_for_offer_request: true) }
    let!(:category_three) { create(:category) }
    let!(:category_four_without_available_for_offer_request) {
      create(:category, questionnaire: questionnaire_two, available_for_offer_request: false)
    }

    let!(:user) { create(:user) }

    before do
      json_get_v2 "/api/categories/for_request_offer"
    end

    it "returns all the categories that have questionnaires" do
      expect(response.status).to eq(200)
      expect(json_response.categories.count).to be(2)
    end

    it "returns the names for the categories" do
      expect(json_response.categories[0].name).not_to eq(nil)
    end

    it "returns the search tokens if available" do
      expect(json_response.categories.find { |cat| cat.id == category_one.id }.search_tokens).to eq(["hello"])
      expect(json_response.categories.find { |cat| cat.id == category_two.id }.search_tokens).to eq([])
    end

    it "returns the questionnaire ids for the categories" do
      expect(json_response.categories[0].questionnaire_id).not_to eq(nil)
    end

    it "returns the questionnaire identifier if availible" do
      expect(json_response.categories[0].questionnaire.identifier).not_to eq(nil)
    end
  end
end
