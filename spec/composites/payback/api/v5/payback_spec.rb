# frozen_string_literal: true

require "rails_helper"
require "composites/payback/repositories/customer_repository"
require "composites/payback/interactors/update_payback_number"

describe Payback::Api::V5::Payback, :integration, type: :request do
  let(:mandate_with_payback_data) { create(:mandate, :payback_with_data) }
  let(:payback_mandate) { create(:mandate, :payback) }
  let(:mandate) { create(:mandate, lead: create(:lead)) }
  let(:params) { {loyalty: {payback: {paybackNumber: ""}}} }
  let(:valid_payback_number) { "6373194456" }
  let(:payback_de_prefix) { ::Payback::Interactors::UpdatePaybackNumber::PAYBACK_DE_PREFIX }

  describe "GET /api/payback/customer" do
    context "when the customer is not authenticated" do
      it "returns 401 code" do
        json_get_v5("/api/payback/customer")
        expect(response.status).to eq 401
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when the customer is authenticated" do
      it "returns 200 code and payback_data" do
        login_as mandate_with_payback_data.user, scope: :user
        repo = Payback::Repositories::CustomerRepository.new
        customer = repo.find(mandate_with_payback_data.id)

        json_get_v5("/api/payback/customer")

        expect(response.status).to eq 200
        expect(json_response["data"]["attributes"]["payback_enabled"]).to eq customer.payback_enabled
        expect(json_response["data"]["attributes"]["payback_data"]).to eq(customer.payback_data)
      end
    end
  end

  describe "PUT /api/payback/customer/enable" do
    context "when the customer is allowed" do
      it "returns 200 and enable payback on customer" do
        login_as mandate.lead, scope: :lead

        json_put_v5("/api/payback/customer/enable")

        expect(response.status).to eq 200
        expect(json_response["data"]["attributes"]["payback_enabled"]).to be_truthy
      end
    end

    context "when the customer is not allowed" do
      let(:accepted_mandate) { create(:mandate, user: create(:user), state: "accepted") }
      let(:created_mandate) { create(:mandate, lead: create(:lead), state: "created") }

      it "returns 401 code for accepted mandate" do
        login_as accepted_mandate.user, scope: :user

        json_put_v5("/api/payback/customer/enable")

        expect(response.status).to eq 400
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end

      it "returns 401 code for created mandate" do
        login_as created_mandate.lead, scope: :lead

        json_put_v5("/api/payback/customer/enable")

        expect(response.status).to eq 400
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end
    end
  end

  describe "PUT /api/payback/customer" do
    context "when the customer is not authenticated" do
      it "returns 401 code" do
        json_put_v5("/api/payback/customer")

        expect(response.status).to eq 401
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when the data is invalid" do
      before do
        login_as payback_mandate.lead, scope: :lead
      end

      it "returns validation error when payback number is blank" do
        json_put_v5 "/api/payback/customer", params
        expect(response.status).to eq 400
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end

      it "returns validation error when the payback number is not luhn valid" do
        params[:loyalty][:payback][:paybackNumber] = "1234567"
        json_put_v5 "/api/payback/customer", params
        expect(response.status).to eq 400
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end

      it "returns validation error when the number is already taken" do
        params[:loyalty][:payback][:paybackNumber] = valid_payback_number

        full_payback_number = payback_de_prefix + valid_payback_number

        create(:mandate, :payback_with_data, paybackNumber: full_payback_number, state: "accepted")

        json_put_v5 "/api/payback/customer", params
        expect(response.status).to eq 400
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when mandate has payback disabled" do
      it "return validation error" do
        mandate = create(:mandate, user: create(:user), state: "accepted")

        login_as mandate.user, scope: :user

        params[:loyalty][:payback][:paybackNumber] = valid_payback_number

        json_put_v5 "/api/payback/customer", params
        expect(response.status).to eq 400
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end
    end

    context "when the payback is enabled and data is valid" do
      let(:expected_payback_data) {
        {
          "paybackNumber" => payback_de_prefix + valid_payback_number,
          "rewardedPoints" => {
            "locked" => 0,
            "unlocked" => 0
          }
        }
      }

      it "return 200 and saves payback_data" do
        login_as payback_mandate.lead, scope: :lead

        params[:loyalty][:payback][:paybackNumber] = valid_payback_number

        json_put_v5 "/api/payback/customer", params
        expect(response.status).to eq 200
        expect(json_response["data"]["attributes"]["payback_enabled"]).to be_truthy
        expect(json_response["data"]["attributes"]["payback_data"]).to eq(expected_payback_data)
      end
    end
  end
end
