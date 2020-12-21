# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Partners::Helpers::Authentication, :integration do
  before :all do
    class DummyEndpoint
      include ClarkAPI::Partners::Helpers::Authentication

      def initialize(access_token)
        @access_token = access_token
      end

      def call_api
        check_access_token(@access_token)
        # then do nothing
      end

      private

      def error_response!(status)
        return 401 if status == :unauthorized
      end
    end
  end

  let(:client) { create(:api_partner) }

  context "without valid access_token" do
    it "returns 401" do
      expect(DummyEndpoint.new("wrong_access_key").call_api).to eq(401)
    end
  end

  context "with valid access_token" do
    it "returns client object" do
      client.save_secret_key!("raw")
      client.update_access_token_for_instance!("test")
      expect(DummyEndpoint.new(client.access_tokens.first["value"]).call_api).to eq(client)
    end
  end
end
