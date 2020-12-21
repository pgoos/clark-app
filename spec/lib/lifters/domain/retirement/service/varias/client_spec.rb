# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Service::Varias::Client do
  subject do
    described_class.new(
      encoded_token: "encoded_token",
      host: "host",
      port: 443
    )
  end

  let(:http_response) do
    response = double
    allow(response).to receive(:code).and_return("200")
    allow(response).to receive(:body).and_return({}.to_json)
    response
  end

  let(:http_client) do
    client = double
    allow(client).to receive(:request).and_return(http_response)
    client
  end

  let(:http_client_with_socket_error) do
    client = double
    allow(client).to receive(:request).and_raise(SocketError)
    client
  end

  let(:http_client_with_unknown_error) do
    client = double
    allow(client).to receive(:request).and_raise("unknown")
    client
  end

  describe "#call" do
    before do
      allow_any_instance_of(described_class).to(
        receive(:build_client).and_return(client)
      )
    end

    context "when request is correct" do
      let(:client) { http_client }

      it "returns success result" do
        expect(subject.call("path", {})).to be_success
      end
    end

    context "when connection failed" do
      context "with socket error" do
        let(:client) { http_client_with_socket_error }

        it "returns failure" do
          result = subject.call("path", {})
          expect(result).to be_failure
          expect(result.errors).to contain_exactly(
            { unparsable: "socket_error" }
          )
        end
      end

      context "with unknown error" do
        let(:client) { http_client_with_unknown_error }

        it "raises the error" do
          expect { subject.call("path", {}) }.to raise_error("unknown")
        end
      end
    end
  end
end
