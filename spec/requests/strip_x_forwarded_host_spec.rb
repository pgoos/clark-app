# frozen_string_literal: true

require "rails_helper"

RSpec.describe "strip X-Forwarded-Host spec", :integration, type: :request do
  it "strips out X-Forwarded-Host header when we send it" do
    get "/de/admin/login", params: {}, headers: {"X-Forwarded-Host" => "evil-attacker.com"}

    expect(response.body).not_to include("evil-attacker.com")
  end
end
