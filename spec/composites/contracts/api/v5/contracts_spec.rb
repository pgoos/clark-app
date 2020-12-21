# frozen_string_literal: true

require "rails_helper"

describe ::Contracts::Api::V5::Contracts, :integration, type: :request do
  describe "POST /api/contracts/current" do
    let(:vertical) { create :vertical }
    let(:customer) { create(:customer, :prospect) }
    let(:category) { create(:category, vertical: vertical) }
    let(:company) { create(:company) }

    before { create(:subcompany, company: company, verticals: [vertical], principal: true) }

    context "with valid params" do
      let(:valid_params) do
        {
          data: [
            {
              categoryIdent: category.ident,
              companyIdent: company.ident,
              shared: false
            }
          ]
        }
      end

      it "creates new contracts for customer" do
        login_customer(customer, scope: :lead)

        json_post_v5 "/api/contracts/current", valid_params

        expect(response.status).to eq 201
        expect(json_response["data"]).to be_kind_of Array
        json_response["data"].each do |contract|
          expect(contract["id"]).not_to be nil
          expect(contract["type"]).to eq "contract"

          contract_attributes = contract["attributes"]
          expect(contract_attributes["state"]).to eq "customer_provided"
          expect(contract_attributes["category_ident"]).to eq category.ident
          expect(contract_attributes["category_name"]).to eq category.name
          expect(contract_attributes["plan_name"]).to eq "#{category.name} #{company.name}"
          expect(contract_attributes["shared"]).to be_in([true, false])
        end
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { data: [{ categoryIdent: "FOO", companyIdent: "BAR", shared: false }] } }

      it "creates contracts for customer" do
        login_customer(customer, scope: :lead)

        json_post_v5 "/api/contracts/current", invalid_params
        expect(response.status).to eq 422
        expect(json_response.errors).to be_kind_of Array
        expect(json_response.errors).not_to be_empty
      end
    end
  end
end
