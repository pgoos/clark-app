# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::AutomationHelpers::Scripts, :integration do
  describe "PUT /api/automation_helpers/feature_switch/switch_setting_app_feature" do
    API_ROUTE = "/api/automation_helpers/feature_switch/switch_setting_app_feature"

    after do
      Settings.reload!
    end

    it "turn on self_service_products application setting feature" do
      script_params = {active: true, key: "self_service_products"}
      json_auto_helper_put API_ROUTE, script_params: script_params
      expect(response.status).to eq(200)
      expect(Settings.app_features.self_service_products).to be_truthy
    end

    it "turn off self_service_products application setting feature" do
      script_params = {active: false, key: "self_service_products"}
      json_auto_helper_put API_ROUTE, script_params: script_params
      expect(response.status).to eq(200)
      expect(Settings.app_features.self_service_products).to be_falsey
    end
  end
end
