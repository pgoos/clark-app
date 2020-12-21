# frozen_string_literal: true

require "swagger_helper"

describe Offers::Api::Admin::V2::Opportunities, :integration, type: :request, swagger_doc: "v2/admin.yaml" do
  let("Content-Type".to_sym) { "application/json" }
  let(:accept) { "application/vnd.clark-admin-v2+json" }
  let(:mandate) { create(:mandate, customer_state: customer_state) }
  let(:opportunity) { create(:opportunity_with_offer, mandate: mandate) }
  let(:customer_state) { nil }
  let(:admin) { create(:admin) }

  path "/api/admin/opportunities/{id}" do
    get "Get opportunity details" do
      consumes "application/json"
      parameter name: :id, in: :path, schema: { type: :string }, description: "Opportunity ID"
      parameter name: :accept, in: :header, schema: { type: :string }
      parameter name: "Content-Type".to_sym, in: :header, schema: { type: :string }

      response "401", "without authentication" do
        let(:id) { opportunity.id }
        run_test!
      end

      response "401", "for non existing opportunity" do
        let(:id) { 1111 }
        run_test!
      end

      response "200", "for existing opportunity" do
        let(:id) { opportunity.id }
        let!(:coverages) do
          opportunity.offer.offer_options.each do |option|
            coverage = option.product.coverage_features.first
            option.product.update!(
              coverages: {
                coverage.identifier => { "value" => "100", "currency" => "EUR" }
              }
            )
          end
        end
        let!(:documents) do
          opportunity.offer.offer_options.each_with_object({}) do |option, hash|
            option.product.documents << create(:document)
            hash[option.id] = option.product.documents
          end
        end

        before do
          login_as(admin, scope: :admin)
        end

        run_test! do |_response|
          response_data = json_response[:data][:attributes]

          expect(json_response[:data][:id]).to eq opportunity.id
          expect(response_data[:mandate_id]).to eq opportunity.mandate_id
          expect(response_data[:state]).to eq opportunity.state
          expect(response_data[:category_ident]).to eq opportunity.category.ident
          expect(response_data[:category_name]).to eq opportunity.category.name
          expect(response_data[:offer_id]).to eq opportunity.offer.id
          expect(response_data[:offer_state]).to eq opportunity.offer.state
          expect(response_data[:displayed_coverage_features]).to eq opportunity.offer.displayed_coverage_features
          expect(response_data[:active_offer_selected]).to eq opportunity.offer.active_offer_selected
          expect(response_data[:offer_rule_id]).to eq opportunity.offer.offer_rule_id
          expect(response_data[:customer_name]).to eq opportunity.mandate.name
          expect(response_data[:note_to_customer]).to eq opportunity.offer.note_to_customer

          opportunity.offer.offer_options.map do |option|
            expect(response_data[:offer_options]).to include hash_including(
              "offer_option_id"        => option.id,
              "plan_ident"             => option.plan_ident,
              "contract_id"            => option.product.id,
              "option_type"            => option.option_type,
              "premium_price_cents"    => option.product.premium_price_cents,
              "premium_price_currency" => option.product.premium_price_currency,
              "premium_period"         => option.product.premium_period,
              "contract_start"         => option.product.contract_started_at,
              "contract_end"           => option.product.contract_ended_at,
              "coverages"              => coverages_hash(option)
            )
          end

          response_data[:offer_options].each do |offer_option_payload|
            expect(offer_option_payload["documents"]).not_to be_empty

            expected_document = documents[offer_option_payload["offer_option_id"]].first
            expected_document_hash = {
              "id"                => expected_document.id,
              "document_type_key" => expected_document.document_type_key,
              "url"               => expected_document.url,
              "name"              => expected_document.name
            }
            document_payload = offer_option_payload["documents"].first
            expect(document_payload).to include(expected_document_hash)
          end
        end

        def coverages_hash(option)
          coverages = opportunity.offer.offer_options.find { |oo| oo.id == option.id }.product.coverages
          coverages.each_with_object({}) do |(key, value), hash|
            hash[key] = { "value" => value.value, "currency" => value.currency }
          end
        end
      end
    end
  end
end
