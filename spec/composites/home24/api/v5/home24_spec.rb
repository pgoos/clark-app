# frozen_string_literal: true

require "rails_helper"
require "composites/home24/repositories/customer_repository"

describe Home24::Api::V5::Home24, :integration, type: :request do
  include_context "home24 with order"

  let(:order_number) { home24_order_number }
  let(:mandate) { create(:mandate, :home24) }

  describe "GET /api/home24/customer" do
    context "when the customer is not authenticated" do
      it "returns 401 code" do
        json_get_v5("/api/home24/customer")
        expect(response.status).to eq 401
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when the customer is authenticated" do
      it "returns 200 code and home24 data" do
        login_as mandate.user, scope: :user
        repo = Home24::Repositories::CustomerRepository.new
        customer = repo.find(mandate.id)

        json_get_v5("/api/home24/customer")

        expect(response.status).to eq 200
        expect(json_response["data"]["attributes"]["home24_source"]).to eq customer.home24_source
      end
    end
  end

  describe "PATCH /api/home24/customer" do
    let(:home24_mandate) {
      create(
        :mandate,
        :home24,
        lead: create(
          :lead,
          :home24
        )
      )
    }
    let(:valid_params) { { loyalty: { home24: { orderNumber: order_number } } } }

    context "when the customer is not authenticated" do
      it "returns 401 code" do
        json_patch_v5("/api/home24/customer")
        expect(response.status).to eq 401
      end
    end

    context "when the customer is authenticated" do
      it "returns 200 code and entity with order_number" do
        login_as home24_mandate.lead, scope: :lead

        json_patch_v5("/api/home24/customer", valid_params)

        expect(response.status).to eq 200
        expect(json_response["data"]["attributes"]["order_number"]).to eq(order_number)
      end
    end

    context "when customer is not a home24 customer" do
      let(:mandate) { create(:mandate, :with_lead) }

      it "returns 400 code" do
        login_as mandate.lead, scope: :lead

        json_patch_v5("/api/home24/customer", valid_params)

        expect(response.status).to eq(400)
      end
    end
  end
end
