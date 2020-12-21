# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::AutomationHelpers::Scripts, :integration do
  describe "POST /api/automation_helpers/data_setup/execute/create_offer_setup" do
    let(:category) { create(:category_legal) }
    let(:plan) { create(:plan, category: category) }
    let(:mandate) { create(:mandate, :accepted) }

    it "creates single option offer for a given plan" do
      script_params = {
        plan_idents: [plan.ident],
        customer_id: mandate.id
      }
      json_auto_helper_post "/api/automation_helpers/data_setup/execute/create_offer_setup", script_params: script_params

      puts json_auto_helper_response["error"] if response.status != 201

      expect(response.status).to eq(201)

      # product = Product.find_by(number: product_number)
      # expect(product).to be_present
      # expect(product).to be_takeover_requested
      # product_payload = json_auto_helper_response["products"].first
      # expect(product_payload["number"]).to eq(product_number)
      # expect(product_payload["portfolio_commission_price_cents"]).to eq(1000)
    end
  end
end
