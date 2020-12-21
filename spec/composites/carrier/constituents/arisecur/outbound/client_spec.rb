# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/outbound/client"
require "faraday"
require_relative "api_errors"

RSpec.describe Carrier::Constituents::Arisecur::Outbound::Client do
  subject(:client) { described_class.new.call(options) }

  let(:url) { "test_url" }
  let(:options) { { request_type: request_type, url: url } }

  shared_context "handles success response" do
    let(:status) { 200 }
    let(:success_response) { double(:response, body: "{\"message\": \"Success!\"}", status: status) }

    before do
      stub_const(
        "ENV",
        {
          "ARISECUR_API_HOST" => "https://testhost.com",
          "ARISECUR_API_MANDANT" => "test_mandant",
          "ARISECUR_API_VERSION" => "test_version",
          "ARISECUR_API_VMT" => "test_vmt"
        }
      )
    end

    it "calls proper Faraday method and returns response" do
      expect(Faraday)
        .to receive(request_type)
        .with("https://testhost.com/test_mandant/broker/test_version/rest/test_vmt/test_url")
        .and_return(success_response)
      expect(client).to eq(success_response)
    end
  end

  shared_context "handles error responses" do
    let(:error_response) { double(:response, body: "{\"message\": \"Error!\"}", status: status) }

    before { allow(Faraday).to receive(request_type).and_return(error_response) }

    context "400" do
      let(:status) { 400 }

      include_examples "400 BadRequest"

      context "with 'Digest' in response" do
        let(:error_response) { double(:response, body: "{\"message\": \"Digest error!\"}", status: status) }

        include_examples "400 AuthenticationError"
      end
    end

    context "403" do
      let(:status) { 403 }

      include_examples "403 VermittlerBlocked"
    end

    context "404" do
      let(:status) { 404 }

      include_examples "404 NotFound"
    end

    context "500" do
      let(:status) { 500 }

      include_examples "500 ApiError"
    end
  end

  describe "#call" do
    context "POST request" do
      let(:request_type) { :post }

      include_context "handles success response"
      include_context "handles error responses"
    end

    context "PUT request" do
      let(:request_type) { :put }

      include_context "handles success response"
      include_context "handles error responses"
    end

    context "GET request" do
      let(:request_type) { :get }

      include_context "handles success response"
      include_context "handles error responses"
    end

    context "DELETE request" do
      let(:request_type) { :delete }

      include_context "handles success response"
      include_context "handles error responses"
    end

    context "verb not supported" do
      let(:request_type) { :test }

      it "raises UnsupportedRequestTypeError" do
        expect { client }.to raise_error(
          Carrier::Constituents::Arisecur::Outbound::Errors::UnsupportedRequestTypeError
        )
      end
    end
  end
end
