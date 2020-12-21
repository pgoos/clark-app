# frozen_string_literal: true

require "rails_helper"
require "composites/payback/outbound/client"

RSpec.describe Payback::Outbound::Client do
  subject(:client) { described_class.new(payback_number) }

  let(:payback_number) { "3083422721801587" }

  describe "#initialize" do
    it "soap client should be instance of Savon::Client" do
      expect(client.instance_variable_get(:@soap_client)).to be_kind_of(Savon::Client)
    end
  end

  describe "#call" do
    let(:predefined_data) {
      {
        consumer_identification: {
          consumer_authentication: {
            principal: Settings.payback.principal,
            credential: Settings.payback.credential
          }
        },
        authentication: {
          identification: {
            alias: payback_number
          },
          security: {
            security_type: "0"
          }
        },
        collect_event_data: {
          partner: {
            partner_short_name: Settings.payback.partner_short_name,
            branch_short_name: Settings.payback.branch_short_name
          }
        }
      }
    }

    let(:blank_soap_request_body) { "<soapenv:Envelope/>" }
    let(:blank_savon_response) { instance_double(Savon::Response, body: blank_soap_request_body) }

    before do
      allow(client.instance_variable_get(:@soap_client)).to receive(:call).and_return(nil)

      allow(client.instance_variable_get(:@soap_client)).to \
        receive(:build_request).and_return(blank_savon_response)
      allow(client).to receive(:correct_namespace_tags).and_return(blank_soap_request_body)
    end

    context "when the overwrite for auth and partner data is enabled" do
      it "should call the method for adding the data" do
        expect(client).to receive(:add_auth_and_partner_data)
        client.call(:process_purchase_event, message: {})
      end

      it "should build request xml body using soap client with added data" do
        expect(client.instance_variable_get(:@soap_client)).to receive(:build_request) \
          .with(:process_purchase_event, message: predefined_data)
        client.call(:process_purchase_event, message: {})
      end

      it "should execute the call method in soap client with xml defined string" do
        expect(client.instance_variable_get(:@soap_client)).to receive(:call) \
          .with(:process_purchase_event, hash_including(:xml))
        client.call(:process_purchase_event, message: {})
      end

      it "header should be added in the request xml body" do
        expect(client.instance_variable_get(:@soap_client)).to receive(:call) do |_operation, data|
          expect(data[:xml]).to include "Header/"
        end
        client.call(:process_purchase_event, message: {})
      end
    end

    context "when the overwrite for auth and partner data is disabled" do
      it "should not call the method for adding the auth and partner data" do
        expect(client).not_to receive(:add_auth_and_partner_data)
        client.call(:process_purchase_event, {message: {}}, false)
      end
    end

    context "when there is thrown an Savon::HTTPError exception during the request" do
      let(:http_response) { HTTPI::Response.new(429, {}, {}) }

      before do
        allow(client.instance_variable_get(:@soap_client)).to receive(:call) \
          .and_raise(Savon::HTTPError.new(http_response))
      end

      it "should return savon response" do
        result = client.call(:process_purchase_event, message: {})
        expect(result).to be_kind_of(Savon::Response)
      end

      it "should has the same http code with the one from exception" do
        result = client.call(:process_purchase_event, message: {})
        expect(result.http.code).to eq(http_response.code)
      end
    end

    context "when there is thrown an HTTPClient::TimeoutError exception during the request" do
      before do
        allow(client.instance_variable_get(:@soap_client)).to receive(:call) \
          .and_raise(HTTPClient::ConnectTimeoutError)
      end

      it "should return savon response" do
        result = client.call(:process_purchase_event, message: {})
        expect(result).to be_kind_of(Savon::Response)
      end

      it "the http status code should be TIMEOUT_ERROR_CODE" do
        result = client.call(:process_purchase_event, message: {})
        expect(result.http.code).to eq(described_class::TIMEOUT_ERROR_CODE)
      end
    end
  end

  describe ".configurations_available?" do
    context "when the configurations are available" do
      before do
        allow(Settings).to receive_message_chain(:payback, :api_end_point).and_return("https://test.org")
      end

      it "returns true" do
        expect(described_class.configurations_available?).to be_truthy
      end
    end

    context "when the configurations are not available" do
      before do
        allow(Settings).to receive_message_chain(:payback, :api_end_point).and_return("")
      end

      it "returns false" do
        expect(described_class.configurations_available?).to be_falsy
      end
    end
  end
end
