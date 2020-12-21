# frozen_string_literal: true

require "rails_helper"

RSpec.describe HealthChecksController, :integration, type: :controller do
  it "should return HTTP 200 OK" do
    get :heartbeat
    expect(response.status).to eq(200)
  end

  it "should return a json with a success message" do
    get :heartbeat
    expect(json_response.message).to eq("It's alive!")
  end

  it "should not extend ApplicationController: avoid dependencies exceeding the heartbeat" do
    expect(subject).not_to be_a(ApplicationController)
  end
end
