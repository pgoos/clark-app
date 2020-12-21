# frozen_string_literal: true

require "rails_helper"

describe Customer::Api::V5::Profile, :integration, type: :request do
  let(:customer) { create(:customer, :self_service) }
  let(:mandate)  { Mandate.find customer.id }

  before do
    login_customer(customer, scope: :user)
  end

  describe "GET /api/customer/current/profile" do
    it "returns profile information about current customer" do
      json_get_v5 "/api/customer/current/profile"

      expect(response.status).to eq 200

      expect(json_response["data"]["id"]).to eq customer.id.to_s
      expect(json_response["data"]["type"]).to eq "profile"
      expect(json_response["data"]["attributes"].keys).to eq %w[
        firstName
        lastName
        birthdate
        gender
        phoneNumber
        phoneVerified
        iban
        street
        houseNumber
        zipcode
        city
      ]
    end
  end

  describe "PATCH /api/customer/current/profile" do
    let(:result) { json_response.data }

    before do
      json_patch_v5 "/api/customer/current/profile", attributes
    end

    context "when all attributes are valid" do
      let(:attributes) do
        {
          first_name: "Hero",
          last_name: "Alam",
          gender: "male",
          birthdate: "1990-10-10",
          phone_number: "+491111111111",
          iban: "DE89 3704 0044 0532 0130 00",
          street: "Tongi",
          house_number: "5",
          city: "Frankfurt",
          zipcode: "63065"
        }
      end

      it "updates the whole profile data" do
        expect(response).to have_http_status(:ok)
        expect(result.attributes.state).to eql(customer.customer_state)
        expect(result.id).to eql(customer.id.to_s)
        expect(result.type).to eql("customer")

        expect(mandate.first_name).to eql(attributes[:first_name])
        expect(mandate.last_name).to eql(attributes[:last_name])
        expect(mandate.gender).to eql(attributes[:gender])
        expect(mandate.birthdate.strftime("%F")).to eql(attributes[:birthdate])
        expect(mandate.street).to eql(attributes[:street])
        expect(mandate.house_number).to eql(attributes[:house_number])
        expect(mandate.zipcode).to eql(attributes[:zipcode])
        expect(mandate.city).to eql(attributes[:city])
        expect(mandate.send(:iban)).to eql(attributes[:iban].gsub(" ", ""))
      end
    end

    context "with a single attribute" do
      let(:attributes) { { gender: "female" } }

      it "updates the attribute" do
        expect(response).to have_http_status(:ok)
        expect(mandate.gender).to eql("female")
      end
    end

    context "with some invalid attribute" do
      let(:attributes) do
        {
          first_name: "Hero",
          last_name: "Alam",
          gender: "invalid gender",
          birthdate: "1990-10-10",
          phone_number: "+491111111111",
          iban: "DE89 3704 0044 0532 0130 00",
          street: "Tongi",
          house_number: "5",
          city: "Frankfurt",
          zipcode: "63065"
        }
      end

      let(:error) { json_response.errors[0].meta.data }

      it "returns proper error" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(error.gender).to be_present
      end
    end
  end

  describe "PATCH /api/customer/current/profile/iban" do
    let(:iban) { "DE49 5001 0517 4928 8491 58" }

    before do
      json_patch_v5 "/api/customer/current/profile/iban", attributes
    end

    context "when all attributes are valid" do
      let(:attributes) { { iban: iban, consent: true } }

      it "updates customer IBAN and returns customer profile" do
        expect(response).to have_http_status(:ok)
        expect(json_response.customer_id).to eql(customer.id)
        expect(mandate.send(:iban)).to eql(attributes[:iban].delete(" "))
      end
    end

    context "when an attribute is missed" do
      let(:attributes) { { iban: iban } }

      it "returns a proper error" do
        expect(response).to have_http_status(:bad_request)
        expect(json_response.errors.length).to eq(1)
        expect(json_response.errors.first["code"]).to eq("consent")
      end
    end

    context "when attributes are invalid" do
      let(:attributes) { { iban: "DE66 5001 0517 5131 2768 9132", consent: false } }
      let(:expected_response) do
        { errors:
                [{ source: { pointer: "iban" }, title: "ist nicht gültig" },
                 { source: { pointer: "consent" }, title: "Muss ausgewählt sein." }] }.as_json
      end

      it "returns the proper errors" do
        expect(response).to      have_http_status(:unprocessable_entity)
        expect(json_response).to eq(expected_response)
      end
    end
  end
end
