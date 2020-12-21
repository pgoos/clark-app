# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::Partners::Healthcheck, :integration do
  it "should provide a health check" do
    endpoint = "/api/healthcheck"
    client   = create(:api_partner)
    client.save_secret_key!("raw")
    client.update_access_token_for_instance!("test")
    access_token = client.access_token_for_instance("test")["value"]

    partners_get(endpoint, headers: {"Authorization" => access_token})

    expect(response.status).to eq(200)
    expect(json_response.message).to eq("It's alive!")
  end
end
