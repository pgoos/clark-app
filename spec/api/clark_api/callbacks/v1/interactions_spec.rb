# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::Callbacks::V1::Interactions, :integration do
  let(:phone_number)  { "+4915123456789" }
  let(:mandate)       { create(:mandate, phone: phone_number) }
  let(:user)          { create(:user, mandate: mandate) }
  let(:admin)         { create(:admin) }
  let(:opportunity)   { create(:opportunity, mandate: mandate) }
  let(:security_token) { "security_token" }
  let(:sms_payload) do
    {}.tap do |sms_data|
      sms_data["messageType"]        = message_type
      sms_data["senderAddress"]      = "4915123456789"
      sms_data["textMessageContent"] = "content"
    end
  end

  before do
    create(:interaction_sms, mandate: mandate, admin: admin, topic: opportunity, phone_number: phone_number)
    allow_any_instance_of(OutboundChannels::Clients::WebSmsClient)
      .to receive(:check_auth_token).with(security_token).and_return(true)
  end

  describe "POST /:security_token/sms/response" do
    context "when message type is text" do
      let(:message_type) { "text" }

      it "secures callbacks using auth token" do
        allow_any_instance_of(OutboundChannels::Clients::WebSmsClient).to receive(:check_auth_token)
          .with(security_token).and_return(false)

        post "/api/callbacks/v1/interactions/#{security_token}/sms/response", params: sms_payload
        expect(response.status).to eq(401)
      end


      it "creates an incoming sms if it could map the incoming sms to an origin" do
        expect {
          post("/api/callbacks/v1/interactions/#{security_token}/sms/response", params: sms_payload)
        }.to change(Interaction::Sms, :count).by(1)
      end

      it "logs error if it could not map the incoming sms to an origin" do
        sms_payload["senderAddress"] = "non existent phone that cannot be mapped to a mandate"
        expect(Rails.logger).to receive(:warn)
        post("/api/callbacks/v1/interactions/#{security_token}/sms/response", params: sms_payload)
        expect(response.status).to eq(201)
      end
    end

    context "when message type is something else" do
      let(:message_type) { "deliveryNotice" }

      it "neglects sms payload but will not fail" do
        expect {
          post("/api/callbacks/v1/interactions/#{security_token}/sms/response", params: sms_payload)
        }.not_to change(Interaction::Sms, :count)
        expect(response.status).to eq(201)
      end
    end
  end
end
