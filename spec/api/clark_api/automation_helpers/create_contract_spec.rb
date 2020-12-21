# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::AutomationHelpers::SetupDataScripts::CreateContract, :integration do
  describe "POST /api/automation_helpers/data_setup/execute/create_contract" do
    it "creates a contract with the analysis state 'details_missing' for a given customer" do
      customer = create(:customer, :mandate_customer)
      email = Mandate.find(customer.id).email

      script_params = {
        customer_email: email
      }
      json_auto_helper_post "/api/automation_helpers/data_setup/execute/create_contract", script_params: script_params

      expect(response.status).to eq(201)
      contract_payload = json_auto_helper_response["contract"]
      expect(contract_payload["analysis_state"]).to eq("details_missing")
      expect(contract_payload["id"]).to be_an(Integer)
    end
  end
end
