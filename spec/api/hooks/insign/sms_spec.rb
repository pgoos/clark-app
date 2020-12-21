# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hooks::Insign::Sms, :integration do
  context "POST /sms" do
    it "sends sms using request params" do
      expect_any_instance_of(OutboundChannels::Sms).to \
        receive(:send_sms).with("USER_PHONE", "SMS_TEXT", "")
      post "/hooks/insign/sms", params: {dest: "USER_PHONE", text: "SMS_TEXT"}
      expect(response.status).to eq 201
      expect(response.body).not_to be_blank
    end
  end
end
