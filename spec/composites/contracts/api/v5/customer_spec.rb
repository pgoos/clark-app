# frozen_string_literal: true

require "rails_helper"

describe ::Customer::Api::V5::Customer, :integration, type: :request do
  describe "POST /api/customer" do
    let(:installation_id) { Faker::Internet.device_token }

    context "when no active session exists" do
      it "creates a new customer and returns 201" do
        json_post_v5 "/api/customer", installation_id: installation_id
        expect(response.status).to eq 201
        lead = Lead.find_by(installation_id: installation_id)
        expect(lead).not_to be_nil
      end

      it "returns error if installation_id already exists" do
        create(:device_lead, installation_id: installation_id)
        json_post_v5 "/api/customer", installation_id: installation_id
        expect(response.status).to eq 422
      end
    end

    context "when customer already has active session" do
      let(:customer) { create(:customer, :prospect) }

      before { login_customer(customer, scope: :lead) }

      it "returns correct respone" do
        # returns 200 if installation_id param is not given
        json_post_v5 "/api/customer"
        expect(response.status).to eq 200

        # updates installation_id if customer doesn't have any installation_id
        json_post_v5 "/api/customer", installation_id: installation_id
        expect(response.status).to eq 200
        lead = Lead.find_by(mandate_id: customer.id, installation_id: installation_id)
        expect(lead).not_to be_nil

        # returns 200 if customer has the same installation_id
        json_post_v5 "/api/customer", installation_id: installation_id
        expect(response.status).to eq 200

        # returns error if customer has different installation_id
        json_post_v5 "/api/customer", installation_id: "rand1237890"
        expect(response.status).to eq 422
      end
    end
  end

  describe "GET /api/customer/current" do
    let(:customer) { create(:customer, :self_service) }

    context "when current_customer is available" do
      before { login_customer(customer, scope: :user) }

      it "returns customer state" do
        json_get_v5 "/api/customer/current"

        expect(response).to have_http_status(:ok)

        expect(json_response["data"]["id"]).to eq(customer.id.to_s)
        expect(json_response["data"]["type"]).to eq("customer")
        expect(json_attributes["state"]).to eq("self_service")
      end
    end

    context "when current_customer is not available" do
      it "responds with 401 http_code" do
        json_get_v5 "/api/customer/current"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
