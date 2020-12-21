# frozen_string_literal: true

require "rails_helper"

describe Customer::Api::V5::PrivacySettings, :integration, type: :request do
  describe "GET /api/customer/current/privacy_settings" do
    context "when current customer has associated privacy settings" do
      let(:customer) { create(:customer, :self_service) }
      let!(:privacy_settings) { create(:privacy_setting, mandate_id: customer.id) }

      it "returns privacy settings" do
        login_customer(customer, scope: :user)

        json_get_v5 "/api/customer/current/privacy_settings"

        expect(response.status).to eq 200

        expect(json_response["data"]["id"]).to eq privacy_settings.id.to_s
        expect(json_response["data"]["type"]).to eq "privacy_settings"
        expect(json_response["data"]["attributes"].keys).to eq %w[
          mandateId
          thirdPartyTracking
        ]
        expect(response.cookies.keys).to include(PrivacySetting::ANALYTICS_TRACKING_COOKIE,
                                                 PrivacySetting::MARKETING_TRACKING_COOKIE,
                                                 PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP,
                                                 PrivacySetting::BANNER_VISIBILITY_COOKIE)
      end
    end

    context "when current customer hasn\'t privacy settings associated" do
      let(:customer) { create(:customer, :self_service) }

      it "returns 404 if any of privacy settings is associated with current customer" do
        login_customer(customer, scope: :user)

        json_get_v5 "/api/customer/current/privacy_settings"

        expect(response.status).to eq 404
      end
    end
  end

  describe "POST /api/customer/current/privacy_settings" do
    context "when valid params are passed" do
      subject(:make_request) do
        login_customer(customer, scope: :user)
        json_post_v5 "/api/customer/current/privacy_settings", params
      end

      let(:customer) { create(:customer, :self_service) }
      let(:accepted_at) { DateTime.now }
      let(:params) { { third_party_tracking: { enabled: true, accepted_at: accepted_at.to_s } } }

      context "customer logged in" do
        context "when previous privacy settings exist" do
          let(:privacy_settings) { create(:privacy_setting, :third_party_tracking_disabled, mandate_id: customer.id) }

          before do
            privacy_settings
            make_request
          end

          it "returns updated privacy settings" do
            expect(response.status).to eq 201
            expect(json_response["data"]["id"]).to eq privacy_settings.id.to_s
            expect(json_response["data"]["type"]).to eq "privacy_settings"
            expect(json_response["data"]["attributes"].keys).to eq %w[
              mandateId thirdPartyTracking
            ]
            expect(json_response["data"]["attributes"]["thirdPartyTracking"]["enabled"]).to eq true
            expect(response.cookies.keys).to include(PrivacySetting::ANALYTICS_TRACKING_COOKIE,
                                                     PrivacySetting::MARKETING_TRACKING_COOKIE,
                                                     PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP,
                                                     PrivacySetting::BANNER_VISIBILITY_COOKIE)
          end
        end

        context "when previous privacy settings does not exist" do
          before do
            make_request
          end

          it "returns created privacy settings" do
            expect(response.status).to eq 201
            expect(json_response["data"]["id"]).not_to be_nil
            expect(json_response["data"]["type"]).to eq "privacy_settings"
            expect(json_response["data"]["attributes"].keys).to eq %w[
              mandateId thirdPartyTracking
            ]
            expect(json_response["data"]["attributes"]["thirdPartyTracking"]["enabled"]).to eq true
            expect(response.cookies.keys).to include(PrivacySetting::ANALYTICS_TRACKING_COOKIE,
                                                     PrivacySetting::MARKETING_TRACKING_COOKIE,
                                                     PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP,
                                                     PrivacySetting::BANNER_VISIBILITY_COOKIE)
          end
        end
      end

      context "when invalid params are passed" do
        subject(:make_request) do
          login_customer(customer, scope: :user)
          json_post_v5 "/api/customer/current/privacy_settings", params
        end

        let(:customer) { create(:customer, :self_service) }
        let(:params) { { third_party_tracking: { enabled: "NOPE", accepted_at: "some_day" } } }

        before do
          make_request
        end

        it "returns 422 status code with error message" do
          expect(response.status).to eq 422
          expect(json_response["errors"].first["meta"]["data"]["third_party_tracking"].keys.sort).to eq %w[
            accepted_at enabled
          ]
        end
      end
    end

    context "not logged in customer" do
      let(:accepted_at) { DateTime.now }
      let(:params) { { third_party_tracking: { enabled: "true", accepted_at: accepted_at.to_s } } }

      it "returns mocked privacy settings" do
        json_post_v5 "/api/customer/current/privacy_settings", params

        expect(response.status).to eq 201
        expect(json_response["data"]["id"]).to eq "0"
        expect(json_response["data"]["type"]).to eq "privacy_settings"
        expect(json_response["data"]["attributes"].keys).to eq %w[
          mandateId thirdPartyTracking
        ]
        expect(json_response["data"]["attributes"]["thirdPartyTracking"]["enabled"]).to eq true
        expect(response.cookies.keys).to include(PrivacySetting::ANALYTICS_TRACKING_COOKIE,
                                                 PrivacySetting::MARKETING_TRACKING_COOKIE,
                                                 PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP,
                                                 PrivacySetting::BANNER_VISIBILITY_COOKIE)
      end
    end
  end
end
