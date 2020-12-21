# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Partners::Notifiers, :integration do
  let(:endpoint) { "/api/notifiers/register" }

  before do
    @url      = "https://www.clark.de"
    @client   = create(:api_partner)
    @client.save_secret_key!("raw")
    @client.update_access_token_for_instance!("test")
    @access_token = @client.access_token_for_instance("test")["value"]
  end

  describe "Create an inquiry" do
    it_behaves_like "unathorized endpoint of the partnership api"

    context "request param is missing" do
      before do
        partners_post endpoint, headers: {"Authorization" => @access_token}
      end

      it "returns 400 http status" do
        expect(response.status).to eq(400)
      end

      it "returns the error object" do
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end

    context "all params are valid" do
      before do
        partners_post endpoint, payload_hash: {base_url: @url},
                                 headers:      {"Authorization" => @access_token}
      end

      it "returns 201" do
        expect(response.status).to eq(201)
      end

      it "saves the webhook base url" do
        @client.reload
        expect(@client.webhook_base_url).to eq(@url)
      end
    end
  end
end
