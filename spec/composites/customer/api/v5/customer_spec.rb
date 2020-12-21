# frozen_string_literal: true

require "rails_helper"

describe Customer::Api::V5::Customer, :integration, type: :request do
  before do
    allow(Settings).to receive_message_chain(:app_features, :clark2) { true }
  end

  describe "POST /api/customer" do
    context "with authenticated customer" do
      context "when customer is registered" do
        it "returns 200" do
          mandate = create(:mandate)
          user = create(:user, mandate: mandate, installation_id: "FOO")

          login_as(user, scope: :user)
          json_post_v5 "/api/customer", { installation_id: "BAR" }
          expect(response.status).to eq 200
          expect(user.reload.installation_id).to eq "FOO"
        end
      end

      context "when customer is not registered" do
        context "when installation_id is different from the current one" do
          it "returns 422" do
            mandate = create(:mandate)
            lead = create(:lead, mandate: mandate, installation_id: "FOO")

            login_as(lead, scope: :lead)
            json_post_v5 "/api/customer", { installation_id: "BAR" }
            expect(response.status).to eq 422
          end
        end
      end
    end
  end

  describe "POST /api/customer/authenticate" do
    let(:result) { json_response.data }
    let(:mandate) { create(:mandate, customer_state: customer_state) }
    let(:customer_state) { nil }
    let(:customer) { create(customer_kind, mandate: mandate) }
    let(:installation_id) { customer.installation_id }
    let(:params) { { installation_id: installation_id } }

    before do
      json_post_v5 "/api/customer/authenticate", params
    end

    context "no customer with provided installation_id" do
      let(:installation_id) { "12345" }

      it "returns not found" do
        expect(response.status).to eq 404
      end
    end

    context "legacy user" do
      let(:customer_kind) { :device_user }

      it "is unauthorized" do
        expect(response.status).to eq 401
      end
    end

    context "self_service customer" do
      let(:customer_kind) { :device_lead }
      let(:customer_state) { Customer::Entities::Customer::SELF_SERVICE }

      it "is unauthorized" do
        expect(response.status).to eq 401
      end
    end

    context "mandate_customer customer" do
      let(:customer_kind) { :device_lead }
      let(:customer_state) { Customer::Entities::Customer::MANDATE_CUSTOMER }

      it "is unauthorized" do
        expect(response.status).to eq 401
      end
    end

    context "legacy lead" do
      let(:customer_kind) { :device_lead }

      it "authenticates user" do
        expect(response.status).to eq 200
        expect(result.attributes.state).to be_nil
        expect(result.id).to eql(mandate.id.to_s)
        expect(result.type).to eql("customer")
      end
    end

    context "prospect customer" do
      let(:customer_kind) { :device_lead }
      let(:customer_state) { Customer::Entities::Customer::PROSPECT }

      it "authenticates user" do
        expect(response.status).to eq 200
        expect(result.attributes.state).to eql(Customer::Entities::Customer::PROSPECT)
        expect(result.id).to eql(mandate.id.to_s)
        expect(result.type).to eql("customer")
      end
    end
  end

  describe "POST /api/customer/firestarter" do
    let(:params) { { override_variant: "2" } }
    let(:customer) { nil }
    let(:referrer) { nil }
    let(:tracking_events) { Tracking::Event.where(name: "customer/clark-version:decision") }
    let(:user_agent) { "Mozilla/5.0 ... (Device: x86_64 iOS: 13.4.1) Clark/0.1.3 Firestarter/0.1.0" }
    let(:adjust_params) { { network: "FOO" } }

    before do
      create :clark2_configuration, :ios_probability
      create :clark2_configuration, :android_probability
      create :clark2_configuration, :other_probability

      login_customer(customer, scope: :user) if customer
      json_post_v5 "/api/customer/firestarter", params, { HTTP_USER_AGENT: user_agent, REFERER: referrer }
    end

    context "with legacy user agent" do
      let(:user_agent) { "Mozilla/5.0 ... (Device: x86_64 iOS: 13.4.1) Clark/0.1.1" }

      it "returns clark1 variant" do
        expect(response.status).to eq 200
        expect(json_response["clark_version"]).to eq "1"
      end
    end

    context "with tracking parameters" do
      let(:params) do
        {
          adjust: {
            adgroup: "base",
            network: "mam",
            campaign: "mam_promotion_4",
            creative: "app_basic_slot_mar",
            adid: "adjust_device_identifier"
          }
        }
      end

      it "saves data in ahoy visit" do
        expect(response.status).to eq 200
        visit = Tracking::Visit.last
        expect(visit).to be_present
        expect(visit.utm_source).to eq params[:adjust][:network]
        expect(visit.utm_content).to eq params[:adjust][:adgroup]
        expect(visit.utm_term).to eq params[:adjust][:creative]
        expect(visit.utm_campaign).to eq params[:adjust][:campaign]
        expect(visit.adid).to eq params[:adjust][:adid]
      end

      it "does not change visit without tracking parameters" do
        # Fire one more request without tracking parameters
        # NOTE: first request with tracking parameters is fired in before block.
        json_post_v5("/api/customer/firestarter", {})

        visit = Tracking::Visit.last
        expect(visit).to be_present
        expect(visit.utm_source).to eq params[:adjust][:network]
      end

      context "with browser" do
        let(:referrer) { "https://www.example.com/de/app/contracts?" + Rack::Utils.build_query(params) }
        let(:user_agent) { Faker::Internet.user_agent }

        let(:params) do
          {
            utm_content:  "base",
            utm_source:   "mam",
            utm_campaign: "mam_promotion_4",
            utm_term:     "app_basic_slot_mar"
          }
        end

        it "saves data in ahoy visit using referrer" do
          expect(response.status).to eq 200
          visit = Tracking::Visit.last

          expect(visit).to be_present
          expect(visit.utm_source).to   eq params[:utm_source]
          expect(visit.utm_content).to  eq params[:utm_content]
          expect(visit.utm_term).to     eq params[:utm_term]
          expect(visit.utm_campaign).to eq params[:utm_campaign]
          expect(visit.landing_page).to eq referrer
        end
      end

      context "when sender is a bot" do
        let(:user_agent) do
          "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) " \
          "Chrome/80.0.3987.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
        end

        it "returns 200" do
          expect(response.status).to eq 200
        end
      end
    end

    context "with override_variant" do
      it "returns 200 containing information for app launcher" do
        expect(response.status).to eq 200
        expect(json_response["csrf_token"]).to be_present
        expect(json_response["clark_version"]).to eq "2"
        expect(json_response["authenticated"]).to eq false
        expect(json_response["customer_state"]).to eq nil
        expect(tracking_events.count).to eq 0
      end
    end

    context "with session customer" do
      let(:customer) { create(:customer, :self_service) }

      it "returns information based on customer state" do
        expect(response.status).to eq 200
        expect(json_response["authenticated"]).to eq true
        expect(json_response["clark_version"]).to eq "2"
        expect(tracking_events.count).to eq 0
      end
    end

    context "with credentials" do
      let(:user)   { create(:user, :with_mandate, password: "Test1234") }
      let(:params) { { user_credentials: { email: user.email, password: "Test1234" } } }

      it "logs customer in as user and returns information based on its state" do
        expect(response.status).to eq 200
        expect(json_response["authenticated"]).to eq true
        expect(json_response["clark_version"]).to eq "1"
        expect(@integration_session.request.env["warden"].user(:user)).to eq user
        expect(tracking_events.count).to eq 0
      end

      context "with invalid credentials" do
        let(:user)   { create(:user, :with_mandate, password: "Test1234") }
        let(:params) { { user_credentials: { email: user.email, password: "FOO" }, adjust: adjust_params } }

        it "does not log customer in and returns random clark version" do
          expect(response.status).to eq 200
          expect(json_response["authenticated"]).to eq false
          expect(json_response["clark_version"]).not_to be_nil
          expect(@integration_session.request.env["warden"].user(:user)).to eq nil

          # Logs tracking information
          expect(tracking_events.count).to eq 1
          expect(tracking_events.last.properties["clarkVersion"]).to eq json_response["clark_version"]
        end
      end
    end

    context "with installation id" do
      let(:mandate) { create(:mandate, :prospect_customer) }
      let(:lead)    { create(:lead, mandate: mandate, installation_id: "INST_ID") }
      let(:params)  { { installation_id: lead.installation_id } }

      it "logs customer in as user returns information based on its state" do
        expect(response.status).to eq 200
        expect(json_response["authenticated"]).to eq true
        expect(json_response["clark_version"]).to eq "2"
        expect(json_response["installation_id_already_registered"]).to eq false
        expect(@integration_session.request.env["warden"].user(:lead)).to eq lead
        expect(tracking_events.count).to eq 0
      end

      context "when installation_id belongs to a registered customer" do
        let(:mandate) { create(:mandate, :self_service_customer) }
        let(:user) { create(:user, mandate: mandate, installation_id: "INST_ID") }
        let(:params) { { installation_id: user.installation_id } }

        it "does not authenticate customer" do
          expect(response.status).to eq 200
          expect(json_response["authenticated"]).to eq false
          expect(json_response["installation_id_already_registered"]).to eq true
          expect(@integration_session.request.env["warden"].user(:lead)).to eq nil
          expect(@integration_session.request.env["warden"].user(:user)).to eq nil
        end

        context "when customer has device this such installation id" do
          let(:user) { create(:user, mandate: mandate) }
          let(:device) { create(:device, user: user, installation_id: "INST_ID") }
          let(:params) { { installation_id: device.installation_id } }

          it "does not authenticate customer" do
            expect(response.status).to eq 200
            expect(json_response["authenticated"]).to eq false
            expect(json_response["installation_id_already_registered"]).to eq true
            expect(@integration_session.request.env["warden"].user(:lead)).to eq nil
            expect(@integration_session.request.env["warden"].user(:user)).to eq nil
          end
        end
      end

      context "with wrong installation_id" do
        let(:lead)   { create(:lead, :with_mandate, installation_id: "INST_ID") }
        let(:params) { { installation_id: "FOO", adjust: adjust_params } }

        it "does not log customer in and returns random clark version" do
          expect(response.status).to eq 200
          expect(json_response["authenticated"]).to eq false
          expect(json_response["clark_version"]).not_to be_nil
          expect(@integration_session.request.env["warden"].user(:lead)).to eq nil

          # Logs tracking information
          expect(tracking_events.count).to eq 1
          expect(tracking_events.last.properties["clarkVersion"]).to eq json_response["clark_version"]
        end
      end
    end
  end
end
