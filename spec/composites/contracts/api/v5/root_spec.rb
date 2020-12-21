# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V5::Root, type: :request do
  let(:exception) { json_response.dig("errors").first }
  let(:code) { exception.dig("code") }
  let(:title) { exception.dig("title") }

  described_class.class_eval do
    get :generic_error do
      raise "Runtime generic error"
    end

    get :validation_errors do
      raise Grape::Exceptions::ValidationErrors.new
    end
  end

  it "generic error" do
    json_get_v5 "/api/generic_error"

    expect(response).to have_http_status(:internal_server_error)
    expect(code).to eql("RuntimeError")
    expect(title).to eql("Runtime generic error")
  end

  it "method not allowed error" do
    json_post_v5 "/api/generic_error"

    expect(response).to have_http_status(:method_not_allowed)
    expect(code).to eql("Grape::Exceptions::MethodNotAllowed")
    expect(title).to eql("405 Not Allowed")
  end

  it "rescue from grape validation errors" do
    json_get_v5 "/api/validation_errors"
    expect(response).to have_http_status(:bad_request)
  end
end
