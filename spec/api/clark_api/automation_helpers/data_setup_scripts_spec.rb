# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::AutomationHelpers::Scripts, :integration do
  describe "POST /api/automation_helpers/data_setup/execute/:ident" do
    let(:category) { create(:category_phv) }
    let(:company) { create(:company) }

    before do
      create(:plan, category: category, company: company)
    end

    it "executes a script to setup data on the target node" do
      product_number = SecureRandom.uuid
      expect(Product.where(number: product_number)).not_to be_present

      script_params = {
        products:
              [
                { attributes: {
                  plan: {
                    category_name: category.name,
                    company_name: company.name
                  },
                  number: product_number,
                  state: :takeover_requested
                } }
              ]
      }

      json_auto_helper_post "/api/automation_helpers/data_setup/execute/setup_products", script_params: script_params

      puts json_auto_helper_response["error"] if response.status != 201

      expect(response.status).to eq(201)
      product = Product.find_by(number: product_number)
      expect(product).to be_present
      expect(product).to be_takeover_requested
      product_payload = json_auto_helper_response["products"].first
      expect(product_payload["number"]).to eq(product_number)
      expect(product_payload["portfolio_commission_price_cents"]).to eq(1000)
    end

    it "receives an error, if the script execution fails" do
      script_params = {
        products: [
          { traits: [], attributes: { plan: nil } }
        ]
      }
      json_auto_helper_post "/api/automation_helpers/data_setup/execute/setup_products", script_params: script_params

      expect(response.status).to eq(400)
      # This is how you can access the error message from here:
      # puts json_auto_helper_response["error"]
      # On the client side (cucumber), you have to parse the JSON first. Find the error with the json key 'error'.
      expect(json_auto_helper_response["error"]).not_to be_empty
    end

    it "should not allow this endpoint in production" do
      allow(Rails.env).to receive(:production?).and_return(true)

      script_params = {
        products: [
          { traits: [:takeover_requested], attributes: {} }
        ]
      }
      json_auto_helper_post "/api/automation_helpers/data_setup/execute/setup_products", script_params: script_params

      expect(response.status).to eq(401)

      allow(Rails.env).to receive(:production?).and_call_original
    end
  end
end
