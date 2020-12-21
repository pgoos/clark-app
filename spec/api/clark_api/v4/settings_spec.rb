# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Settings, :integration do
  let(:user) { create(:user, :with_mandate) }

  before do
    allow_any_instance_of(Domain::Client::ConfigProvider).to \
      receive(:retirement_calculation_pdf).and_return("dummy_url")
    allow_any_instance_of(Domain::Client::ConfigProvider).to \
      receive(:socket_server).and_return("ws:test_url")
    allow_any_instance_of(Domain::Client::ConfigProvider).to \
      receive(:clark2).and_return(false)
  end

  describe "GET /api/settings" do
    it "has a response status 200" do
      login_as(user, scope: :user)
      json_get_v4 "/api/settings"

      expect(response.status).to eq(200)
      expect(json_response.retirement_calculation_pdf).to eq("dummy_url")
      expect(json_response.socket_server).to eq("ws:test_url")
      expect(json_response.socket_server).to eq("ws:test_url")
      expect(json_response.clark2).to eq false
    end
  end
end
