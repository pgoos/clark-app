# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Partners::Companies, :integration do
  let(:endpoint) { "/api/companies" }

  describe "Get all Clark companies" do
    it_behaves_like "unathorized endpoint of the partnership api"

    before do
      client = create(:api_partner)
      client.save_secret_key!("raw")
      client.update_access_token_for_instance!("test")
      access_token = client.access_token_for_instance("test")["value"]
      partners_get endpoint, headers: {"Authorization" => access_token}
    end

    it "returns 200 http status" do
      expect(response.status).to eq(200)
    end

    it "returns the access token object" do
      expect(response.body).to match_response_schema("partners/20170213/companies")
    end
  end
end
