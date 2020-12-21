# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Partners::Authentication, :integration do
  before :all do
    @endpoint = "/api/authentication/oauth"
  end

  describe "Authenticate the client" do
    context "without required params" do
      before :all do
        partners_post @endpoint
      end

      it "returns 400 http status" do
        expect(response.status).to eq(400)
      end

      it "returns the error object" do
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end

    context "with required params" do
      before :all do
        client = create(:api_partner)
        client.save_secret_key!("foo")
        payload = {consumer_key: client.consumer_key, secret_key: "foo", instance_ident: "test"}
        partners_post @endpoint, payload_hash: payload
      end

      it "returns 200 http status" do
        expect(response.status).to eq(201)
      end

      it "returns the access token object" do
        expect(response.body).to match_response_schema("partners/20170213/bearer_token")
      end
    end
  end
end
