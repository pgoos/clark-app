# frozen_string_literal: true

require "swagger_helper"

describe "GET /api/contracts/:id", type: :request, swagger_doc: "v2/contract.yaml", integration: true do
  let(:contract) do
    create(
      :contract,
      :with_customer_uploaded_document,
      :with_valid_products_advice,
      :under_analysis,
      customer_id: customer.id,
      questionnaire: questionnaire
    )
  end
  let(:customer) { create(:customer, :self_service) }
  let(:product) { Product.find(contract.id) }
  let(:company) { product.company }
  let(:subcompany) { product.subcompany }
  let(:category) { product.category }
  let(:coverage_feature) { category.coverage_features.first }
  let(:other_customer) { create(:customer) }
  let(:other_customer_contract) { create(:contract, :details_missing, customer_id: other_customer.id) }
  let(:latest_advice) { product.last_valid_advice }
  let(:premium_price) { product.premium_price }
  let(:currency) { Currency::EURO }
  let(:weekday_time) { Time.strptime("2020-01-02T00:00:00", "%Y-%m-%d") }
  let("Content-Type".to_sym) { "application/json" }
  let(:accept) { "application/vnd.clark-v5+json" }
  let(:questionnaire) { create(:questionnaire) }

  before do
    Timecop.freeze(weekday_time)
  end

  after do
    Timecop.return
  end

  def test_contract_coverages(results)
    (0..2).to_a.each_with_object({}) do |i, _|
      expect(results).to include("name" => "Coverage Feature",
                                 "type" => "Text",
                                 "attributes" => {"text" => "Text #{i}"})
    end
  end

  path "/api/contracts/{id}" do
    get "Get contract" do
      consumes "application/json"
      parameter name: :id, in: :path, schema: { type: :string }, description: "Contract ID"
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: {type: :string}

      response "401", "without authorization" do
        let(:id) { contract.id }
        run_test!
      end

      response "404", "non-existing contract" do
        let(:id) { 9999 }
        let!(:authentication) { login_customer(customer, scope: :user) }
        run_test!
      end

      response "200", "show contract" do
        let(:id) { contract.id }
        let!(:authentication) { login_customer(customer, scope: :user) }
        run_test! do |_response|
          data = json_response["data"]
          expect(data["id"]).to eq contract.id
          expect(data["type"]).to eq "contract"
          expect(json_attributes["state"]).to eq contract.state
          expect(json_attributes["analysis_state"]).to eq contract.analysis_state
          expect(json_attributes["category_ident"]).to eq contract.category_ident
          expect(json_attributes["category_name"]).to eq contract.category_name
          test_contract_coverages(json_attributes["coverages"].as_json)
          expect(json_attributes["category_tips"]).to eq(category.all_tips)
          expect(json_attributes["company_name"]).to eq(company.name)
          expect(json_attributes["company_logo"]).to eq(company.logo_url)
          expect(json_attributes["rating_score"]).to eq(subcompany.rating_score)
          expect(json_attributes["rating_text"]).to eq(subcompany.rating_text_de)
          expect(json_attributes["plan_name"]).to eq(contract.plan_name)
          expect(json_attributes["premium_price"]).to eq(
            "value" => premium_price.cents,
            "currency" => {"currency_symbol" => currency.currency_symbol, "identifier" => currency.identifier},
            "unit" => "Money"
          )
          expect(json_attributes["renewal_period"]).to eq(contract.renewal_period)

          # return corresponsing document details
          document = json_attributes["documents"].first
          expect(json_attributes["documents"].count).to eq(1)
          expect(document["type"]).to eq("document")
          expect(document["id"]).to be_a(Integer)
          expect(document["attributes"]["url"]).to be_a(String)
          expect(document["attributes"]["created_at"]).to be_a(String)
          expect(document["attributes"]["content_type"]).to be_a(String)
          expect(document["attributes"]["file_name"]).to be_a(String)

          # return the latest valid advice
          advice = json_attributes["advice"]
          expect(advice).to be_a(Hash)
          expect(advice["type"]).to eq("advice")
          expect(advice["id"]).to eq(latest_advice.id)
          expect(advice["attributes"]["quality"]).to be_a(String)
          expect(advice["attributes"]["content"]).to eq(latest_advice.content)
          expect(advice["attributes"]["questionnaire_ident"]).to eq(questionnaire.identifier)

          expect(json_attributes["estimated_time_to_finish_analysis"]).to eq((weekday_time + 24.hours).utc.iso8601)
        end
      end
    end
  end
end
