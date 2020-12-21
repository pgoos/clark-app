# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Features, :integration do
  describe "GET /api/features/all" do
    it "returns 401 if token is not valid" do
      json_get_v4 "/api/features/all"

      expect(response.status).to eq(401)
    end

    it "returns all feature switches with their status if active" do
      headers = { Authorization: "Bearer #{::Settings.simple_auth.token}" }

      json_get_v4 "/api/features/all", {}, headers

      expect(response.status).to eq(200)
      expect(json_response.keys).to match_array(::Features::ALL_SWITCHES)
    end
  end

  describe "GET /api/features" do
    let(:switch) do
      exposed = "FEATURE_RETIREMENT_2018_V1"
      result = FeatureSwitch.find_by(key: exposed)
      result = FactoryBot.create(:feature_switch, key: exposed) if result.blank?
      result
    end

    before do
      not_exposed = "API_NOTIFY_PARTNERS"
      if FeatureSwitch.find_by(key: not_exposed).blank?
        FactoryBot.create(:feature_switch, key: not_exposed)
      end

      FactoryBot.create(:feature_switch, key: "EMBER_NAV_BAR", active: true)
    end

    it "returns exposed feature switches with their status if active" do
      switch.update!(active: true)

      json_get_v4 "/api/features"

      expect(response.status).to eq(200)

      expect(json_response.FEATURE_RETIREMENT_2018_V1).to eq(true)

      expect(json_response.EMBER_NAV_BAR).to eq(true)
    end

    it "returns exposed feature switches with their status if inactive" do
      switch.update!(active: false)

      json_get_v4 "/api/features"

      expect(response.status).to eq(200)

      expect(json_response.FEATURE_RETIREMENT_2018_V1).to eq(false)
      expect(json_response.RECOMMENDATION_OVERVIEW_2020).to eq(false)
      expect(json_response.RECOMMENDATION_OVERVIEW_SEGMENT).to eq(false)
      expect(json_response.RECOMMENDATION_OVERVIEW_LIST).to eq(false)
    end

    it "does not return unexposed feature switches" do
      json_get_v4 "/api/features"

      expect(response.status).to eq(200)

      expect(json_response.API_NOTIFY_PARTNERS).to be_nil
    end

    describe "NPS_SURVEY" do
      before do
        FactoryBot.create(:feature_switch, key: "NPS_SURVEY", active: active)
      end

      context "when switch is on" do
        let(:active) { true }

        it "returns flag with true value" do
          json_get_v4 "/api/features"

          expect(response.status).to eq(200)

          expect(json_response.NPS_SURVEY).to eq(true)
        end
      end

      context "when switch is off" do
        let(:active) { false }

        it "returns flag with false value" do
          json_get_v4 "/api/features"

          expect(response.status).to eq(200)

          expect(json_response.NPS_SURVEY).to eq(false)
        end
      end
    end
  end
end
