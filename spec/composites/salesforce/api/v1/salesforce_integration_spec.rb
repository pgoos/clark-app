# frozen_string_literal: true

require "rails_helper"

describe Salesforce::Api::V1::SalesforceIntegration, :integration, type: :request do
  describe ".commands" do
    describe "POST /api/callbacks/v1/salesforce_integration/commands" do
      it "returns 401" do
        post("/api/callbacks/v1/salesforce_integration/commands", params: {})
        expect(response.status).to eq 401
      end

      it "returns 200" do
        allow(Settings.salesforce).to receive(:integration_command_token).and_return("Token")
        params = { id: "id", country: "de", aggregate_type: "opportunity", aggregate_id: 1,
                   predecessor: nil, occured_at: "today", type: "some-type", revision: 1, payload: {} }
        expect {
          post("/api/callbacks/v1/salesforce_integration/commands",
               params: params, headers: { "Authorization" => "Token" })
        }.to have_enqueued_job.on_queue("salesforce")
        expect(response.status).to eq 200
      end
    end
  end
end
