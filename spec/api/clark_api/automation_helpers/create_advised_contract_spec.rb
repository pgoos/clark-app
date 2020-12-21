# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::AutomationHelpers::SetupDataScripts::CreateAdvisedContract, :integration do
  describe "POST /api/automation_helpers/data_setup/execute/create_advised_contract" do
    let!(:category) { create(:category_phv) }
    let!(:plan) { create(:plan, ident: "448de66d", name: "Single Kompakt", category: category) }

    it "creates a contract with the valid advise, analysis state 'details_complete' for a given customer" do
      customer = create(:customer, :mandate_customer)
      email = Mandate.find(customer.id).email

      script_params = {
        customer_email: email
      }
      json_auto_helper_post(
        "/api/automation_helpers/data_setup/execute/create_advised_contract",
        script_params: script_params
      )

      expect(response.status).to eq(201)
      contract_payload = json_auto_helper_response["contract"]
      expect(contract_payload["analysis_state"]).to eq("details_complete")
      expect(contract_payload["id"]).to be_an(Integer)

      advice = Interaction::Advice.where(topic_type: "Product", topic_id: contract_payload["id"]).first
      expect(advice.metadata["valid"]).to be_truthy

      contract = Product.find(contract_payload["id"])
      expect(contract.plan.name).to eq(plan.name)
      expect(contract.category.name).to eq(category.name)
    end
  end
end
