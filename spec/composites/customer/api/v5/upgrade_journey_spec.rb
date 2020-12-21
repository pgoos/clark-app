# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("app", "composites", "customer", "repositories", "customer_repository")

RSpec.shared_examples "it starts upgrade journey" do |expected_status=:created|
  it do
    expect(response).to have_http_status(expected_status)

    expect(json_response.data.attributes["mandateState"]).to eq "in_creation"
    expect(json_response.data.attributes["state"]).to eq "self_service"
  end
end

describe Customer::Api::V5::UpgradeJourney, :integration, :vcr, type: :request do
  let(:customer) { get_customer_entity(mandate.id) }
  let(:customer_state) { "self_service" }

  let(:mandate) do
    create(
      :mandate,
      :with_lead,
      state: state,
      customer_state: customer_state
    )
  end

  describe "POST /api/customer/upgrade_journey/start" do
    let(:endpoint) { :start }

    before do
      login_customer(customer, scope: :lead)
      json_post_v5 "/api/customer/upgrade_journey/#{endpoint}"
    end

    context "when mandate state is not_started" do
      let(:state) { "not_started" }

      it_behaves_like "it starts upgrade journey"
    end

    context "when mandate state is invalid" do
      let(:state) { "accepted" }

      it { expect(response).to have_http_status(:unprocessable_entity) }
    end

    context "when customer has already started upgrade journey" do
      let(:mandate) do
        create(
          :mandate,
          :with_lead,
          :wizard_profiled,
          state: "in_creation",
          customer_state: customer_state
        )
      end

      it_behaves_like "it starts upgrade journey", :ok
    end
  end

  describe "PUT /api/customer/upgrade_journey/profile" do
    let(:state) { "in_creation" }
    let(:customer_state) { "self_service" }
    let(:attributes) do
      {
        first_name: "Hero",
        last_name: "Alam",
        gender: "male",
        birthdate: "10-10-1990",
        phone_number: "+491111111111",
        street: "Tongi",
        house_number: "5",
        city: "Frankfurt",
        zipcode: "63065"
      }
    end

    let(:lead) do
      create(:device_lead, mandate: create(:mandate, state: state, customer_state: customer_state))
    end
    let(:mandate) { lead.mandate }

    before do
      login_customer(customer, scope: :lead)
      json_put_v5 "/api/customer/upgrade_journey/profile", attributes
    end

    context "when upgrade_journey_state is valid" do
      it "updates profile data" do
        expect(json_response.data.attributes["mandateState"]).to eq state
        expect(json_response.data.attributes["state"]).to eq customer_state

        expect(json_response.data.attributes["upgradeJourneyState"]).to eq "signature"
        expected_profile_attributes = {
          firstName: attributes[:first_name],
          lastName: attributes[:last_name],
          gender: attributes[:gender],
          street: attributes[:street],
          houseNumber: attributes[:house_number],
          city: attributes[:city],
          zipcode: attributes[:zipcode]
        }

        expect(json_response).to have_has_one_relationship(customer.id, "profile", expected_profile_attributes)
      end

      it "is idempotent" do
        json_put_v5 "/api/customer/upgrade_journey/profile", attributes
        expect(response).to have_http_status(:ok)
      end
    end

    context "when upgrade_journey_state is invalid" do
      let(:mandate) do
        create(
          :mandate,
          :with_lead,
          :wizard_confirmed,
          skip_signature_validation: true,
          state: state,
          customer_state: customer_state
        )
      end

      it { expect(response).to have_http_status(:unprocessable_entity) }
    end
  end

  describe "GET /api/customer/upgrade_journey/customer" do
    let(:state) { "in_creation" }
    let(:customer_state) { "self_service" }

    it "returns customer with profile data" do
      # when customer is not authorized
      json_get_v5 "/api/customer/upgrade_journey/customer"
      expect(response.status).to eq 401

      # when customer is authorized
      login_customer(customer, scope: :lead)
      json_get_v5 "/api/customer/upgrade_journey/customer"

      expect(response.status).to eq 200
      expect(json_response.data.attributes["mandateState"]).to eq customer.mandate_state
      expect(json_response.data.attributes["state"]).to eq customer.customer_state
      expect(json_response.data.attributes["upgradeJourneyState"]).to eq customer.upgrade_journey_state
      expect(json_response).to have_has_one_relationship(customer.id, "profile", profile_attributes(customer))
    end
  end

  describe "POST /api/customer/upgrade_journey/confirm_signature" do
    let(:customer) { Customer::Repositories::CustomerRepository.new.find(mandate.id) }

    let(:params) do
      {
        insign_session_id: "b8c16f83ebb8ee2dcbaa45a3d2d1bbfca01d132f254" \
                           "d6da235a17844e7e0a099-9608adc2-37f2-4f3c-80d2-694731db329a"
      }
    end

    let(:mandate) do
      create(
        :mandate,
        :with_lead,
        :wizard_profiled,
        state: "in_creation",
        customer_state: "self_service"
      )
    end

    def make_request(params)
      VCR.use_cassette("insign/download_signature", preserve_exact_body_bytes: true) do
        json_post_v5 "/api/customer/upgrade_journey/confirm_signature", params
      end
    end

    it "confirms upgrade journey" do
      login_customer(customer, scope: :lead)

      make_request(params)
      expect(response.status).to eq 201
      expect(json_response.data.attributes["state"]).to eq "mandate_customer"
      expect(json_response.data.attributes["upgradeJourneyState"]).to eq "finished"
      expect(json_response.data.attributes["mandateState"]).to eq "created"
    end

    context "when mandate state is invalid" do
      let(:mandate) do
        create(
          :mandate,
          :with_lead,
          :wizard_profiled,
          state: "accepted",
          customer_state: "self_service"
        )
      end

      it "returns an error" do
        login_customer(customer, scope: :user)

        make_request(params)

        expect(response.status).to eq 422
      end
    end

    context "when customer state is invalid" do
      let(:mandate) do
        create(
          :mandate,
          :with_lead,
          :wizard_profiled,
          state: "in_creation",
          customer_state: "mandate_customer"
        )
      end

      it "returns an error" do
        login_customer(customer, scope: :user)

        make_request(params)

        expect(response.status).to eq 422
      end
    end

    context "when upgrade journey state is invalid" do
      let(:mandate) do
        create(
          :mandate,
          :with_lead,
          state: "in_creation",
          customer_state: "self_service"
        )
      end

      it "returns an error" do
        login_customer(customer, scope: :lead)

        make_request(params)

        expect(response.status).to eq 422
      end
    end
  end

  private

  def get_customer_entity(mandate_id)
    Customer::Constituents::UpgradeJourney::Repositories::CustomerRepository
      .new
      .find(mandate_id, include_profile: true)
  end

  def profile_attributes(customer)
    profile = customer.profile

    {
      firstName: profile.first_name,
      lastName: profile.last_name,
      gender: profile.gender,
      phoneNumber: profile.phone_number,
      street: profile.address.street,
      city: profile.address.city,
      houseNumber: profile.address.house_number,
      zipcode: profile.address.zipcode
    }
  end
end
