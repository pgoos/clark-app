# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::AutomationHelpers::SetupDataScripts::CreateCustomer, :integration do
  describe "POST /api/automation_helpers/data_setup/execute/create_customer" do
    let(:script_params) do
      {attributes: {}}
    end

    it "creates a customer in different variations" do
      # creates a prospect customer per default
      script_params.tap do |params|
        params[:attributes] = params[:attributes].merge(email: Faker::Internet.email)
        params[:attributes] = params[:attributes].merge(birthdate: Faker::Date.birthday)
        params[:attributes] = params[:attributes].merge(password: ClarkFaker::Internet.password)
      end

      json_auto_helper_post "/api/automation_helpers/data_setup/execute/create_customer", script_params: script_params

      expect(response.status).to eq(201)
      customer_payload = json_auto_helper_response["customer"]
      expect(customer_payload["customer_state"]).to eq("prospect")
      expect(customer_payload["email"]).to eq script_params[:attributes][:email]
      expect(customer_payload["birthdate"].to_date).to eq script_params[:attributes][:birthdate]
      expect(customer_payload["id"]).to match(/^\d*$/)

      # it would create a self service customer, if the customer state would be passed
      script_params.tap do |params|
        params[:attributes] = params[:attributes].merge(customer_state: "self_service")
        params[:attributes] = params[:attributes].merge(email: Faker::Internet.email)
        params[:attributes] = params[:attributes].merge(birthdate: Faker::Date.birthday)
        params[:attributes] = params[:attributes].merge(password: ClarkFaker::Internet.password)
      end

      json_auto_helper_post "/api/automation_helpers/data_setup/execute/create_customer", script_params: script_params

      expect(response.status).to eq(201)

      customer_payload = json_auto_helper_response["customer"]
      expect(customer_payload["customer_state"]).to eq("self_service")
      expect(customer_payload["email"]).to eq script_params[:attributes][:email]
      expect(customer_payload["birthdate"].to_date).to eq script_params[:attributes][:birthdate]
      expect(customer_payload["id"]).to match(/^\d*$/)

      # it would create a mandate customer, if the customer state would be passed
      script_params.tap do |params|
        params[:attributes] = params[:attributes].merge(customer_state: "mandate_customer")
        params[:attributes] = params[:attributes].merge(email: Faker::Internet.email)
        params[:attributes] = params[:attributes].merge(birthdate: Faker::Date.birthday)
        params[:attributes] = params[:attributes].merge(password: ClarkFaker::Internet.password)
      end

      json_auto_helper_post "/api/automation_helpers/data_setup/execute/create_customer", script_params: script_params

      expect(response.status).to eq(201)

      customer_payload = json_auto_helper_response["customer"]
      user = User.find_by_email(customer_payload["email"])

      expect(customer_payload["customer_state"]).to eq("mandate_customer")
      expect(customer_payload["email"]).to eq script_params[:attributes][:email]
      expect(customer_payload["birthdate"].to_date).to eq script_params[:attributes][:birthdate]
      expect(customer_payload["id"]).to match(/^\d*$/)
      expect(user.valid_password?(script_params[:attributes][:password])).to be_truthy
    end
  end
end
