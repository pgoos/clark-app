# frozen_string_literal: true

require "rails_helper"

RSpec.describe "checks the presence of some headers", :integration, type: :request do
  it "checks if X-Frame-Options is present and has the value SAMEORIGIN" do
    get "/de/heartbeat"

    expect(response.headers["X-Frame-Options"]).to be("SAMEORIGIN")
  end
end
