# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::Api::V5::Opportunities, :integration, type: :request do
  let(:customer) { create(:customer, :prospect) }

  describe "GET /api/sales/opportunities/:id" do
    let(:opportunity) do
      create(
        :opportunity,
        mandate_id: customer.id,
        previous_damages: "Anything",
        preferred_insurance_start_date: Date.new(2020, 12, 2)
      )
    end

    context "when user is not logged in" do
      it "returns 401" do
        json_patch_v5 "/api/sales/opportunities/10101010"

        expect(response.status).to be(401)
      end
    end

    context "when user is logged in" do
      before { login_customer(customer, scope: :lead) }

      it "returns Opportunity" do
        json_get_v5 "/api/sales/opportunities/#{opportunity.id}"

        %w[
          id
          previous_damages
          preferred_insurance_start_date
        ].each do |attribute|
          expect(json_response[attribute]).to eq(opportunity.public_send(attribute))
        end
      end

      it "returns 404 when mandate doesn't own opportunity" do
        o = create(:opportunity)
        json_get_v5 "/api/sales/opportunities/#{o.id}"

        expect(response.status).to be(404)
      end
    end
  end

  describe "PATCH /api/sales/opportunities/:id/details" do
    let(:preferred_insurance_start_date) { DateTime.new(2020, 6, 26, 15, 55, 0) }
    let(:opportunity) { create(:opportunity, mandate_id: customer.id) }
    let(:params) do
      {
        opportunity: {
          has_previous_damages: true,
          previous_damages: "Something",
          preferred_insurance_start: "later",
          preferred_insurance_start_date: preferred_insurance_start_date
        }
      }
    end

    context "when user is not logged in" do
      it "returns 401" do
        json_patch_v5 "/api/sales/opportunities/#{opportunity.id}/details", params

        expect(response.status).to be(401)
      end
    end

    context "when user is logged in" do
      let(:expected_values) do
        {
          "previous_damages" => "Something",
          "preferred_insurance_start_date" => preferred_insurance_start_date.as_json
        }
      end

      before { login_customer(customer, scope: :lead) }

      it "does not return 401" do
        json_patch_v5 "/api/sales/opportunities/#{opportunity.id}/details", params

        expect(response.status).to be(200)
      end

      it "updates opportunity details" do
        expect(opportunity.previous_damages).to be nil
        expect(opportunity.preferred_insurance_start_date).to be nil

        json_patch_v5 "/api/sales/opportunities/#{opportunity.id}/details", params

        opportunity.reload

        expect(opportunity.metadata).to include(expected_values)
      end

      it "returns a proper success response" do
        json_patch_v5 "/api/sales/opportunities/#{opportunity.id}/details", params

        expected_response = {
          id: opportunity.id,
          preferred_insurance_start_date: preferred_insurance_start_date.as_json,
          previous_damages: "Something"
        }.as_json

        expect(json_response).to eq(expected_response)
      end

      it "returns an error when opportunity does not exist" do
        opportunity_id = 10_001
        json_patch_v5 "/api/sales/opportunities/#{opportunity_id}/details", params

        expect(response.status).to be(404)
      end
    end

    shared_examples "a proper error response" do
      before { login_customer(customer, scope: :lead) }

      it "returns 422" do
        json_patch_v5 "/api/sales/opportunities/#{opportunity.id}/details", params

        expect(response.status).to be(422)
      end

      it "matches the error response" do
        json_patch_v5 "/api/sales/opportunities/#{opportunity.id}/details", params
        expect(json_response).to eq(expected_response)
      end
    end

    context "when has_previous_damages is missing" do
      let(:params) do
        {
          opportunity: {
            has_previous_damages: nil,
            preferred_insurance_start: "later",
            preferred_insurance_start_date: "2020-06-26"
          }
        }
      end
      let(:expected_response) do
        {
          errors: [
            { title: "Muss ausgefüllt werden", source: { pointer: "has_previous_damages" } }
          ]
        }.as_json
      end

      it_behaves_like "a proper error response"
    end

    context "when preferred_insurance_start is missing" do
      let(:params) do
        {
          opportunity: {
            has_previous_damages: false,
            preferred_insurance_start: nil
          }
        }
      end
      let(:expected_response) do
        {
          errors: [
            { title: "Muss ausgefüllt werden", source: { pointer: "preferred_insurance_start" } }
          ]
        }.as_json
      end

      it_behaves_like "a proper error response"
    end
  end
end
