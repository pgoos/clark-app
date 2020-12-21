# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Root, :integration do
  context "CSRF" do
    it "returns 403 when no token is provided and it is required" do
      expect_any_instance_of(ClarkAPI::Helpers::CSRFHelpers).to receive(:verified_request?).and_return(false)
      json_post_v2 "/api/app/register", user: {email: "theo.tester@clark.de", password: "test1234"},
                                        mandate: {first_name: "Theo"}

      expect(response.status).to eq(403)
      expect(json_response.errors.csrf.token.first).to eq("invalid")
    end

    it "returns the authenticity token for v2" do
      json_get_v2 "/api/authenticity-token"

      expect(response.status).to eq(200)
      expect(json_response.token).to be_present
      expect(ClarkAPI::V2::Root::AUTH_TOKEN_HEADER_DESC).not_to be_frozen
    end
  end
end
