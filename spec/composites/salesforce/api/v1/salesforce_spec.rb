# frozen_string_literal: true

require "rails_helper"

describe Salesforce::Api::V1::Salesforce, :integration, type: :request do
  describe ".execute" do
    describe "POST /api/callbacks/v1/salesforce/execute" do
      it "returns 400 if params missed" do
        post("/api/callbacks/v1/salesforce/execute", params: {})
        expect(response.status).to eq 400
      end

      it "performs job for send message" do
        allow(Settings.salesforce).to receive(:messager_auth_token).and_return("token")
        params = { "inArguments" => [{
          clark_id: "de-1",
          message: "Hello",
          cta_text: "hey",
          cta_link: "https://google.com",
          api_key: "token"
        }] }
        expect {
          post("/api/callbacks/v1/salesforce/execute", params: params)
        }.to have_enqueued_job.on_queue("salesforce")
        expect(response.status).to eq 200
        expect(response.body).to eq "{\"ok\":\"works!\"}"
      end

      it "returrns 403 with wrong token" do
        allow(Settings.salesforce).to receive(:messager_auth_token).and_return("token")
        params = { "inArguments" => [{ clark_id: 1, message: "Hello", cta_text: "hey",
                   cta_link: "https://google.com", api_key: "wrong token" }] }
        post("/api/callbacks/v1/salesforce/execute", params: params)
        expect(response.status).to eq 401
      end
    end
  end

  describe ".save" do
    describe "POST /api/callbacks/v1/salesforce/save" do
      it "returns 200" do
        post("/api/callbacks/v1/salesforce/save", params: {})
        expect(response.status).to eq 200
        expect(response.body).to eq "{}"
      end
    end
  end

  describe ".stop" do
    describe "POST /api/callbacks/v1/salesforce/stop" do
      it "returns 200" do
        post("/api/callbacks/v1/salesforce/stop", params: {})
        expect(response.status).to eq 200
        expect(response.body).to eq "{}"
      end
    end
  end

  describe ".publish" do
    describe "POST /api/callbacks/v1/salesforce/publish" do
      it "returns 200" do
        post("/api/callbacks/v1/salesforce/publish", params: {})
        expect(response.status).to eq 200
        expect(response.body).to eq "{}"
      end
    end
  end

  describe ".validate" do
    describe "POST /api/callbacks/v1/salesforce/validate" do
      it "returns 200" do
        post("/api/callbacks/v1/salesforce/validate", params: {})
        expect(response.status).to eq 200
        expect(response.body).to eq "{}"
      end
    end
  end

  describe ".message" do
    describe "POST /api/callbacks/v1/salesforce/message" do
      it "returns 200" do
        post("/api/callbacks/v1/salesforce/message", params: {})
        expect(response.status).to eq 200
        expect(response.body).to eq "{}"
      end
    end
  end
end
