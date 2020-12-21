# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutboundChannels::Clients::WebSmsClient do
  let(:settings) do
    {test_mode: "false", send_sms_end_point: "http://endpoint", api_key: "key", token: "token"}
  end

  before do
    allow(Settings).to receive_message_chain(:sms_clients, :websms).and_return(OpenStruct.new(settings))
  end

  describe "#publish" do
    let(:https) { instance_double(Net::HTTP).as_null_object }
    let(:request) { instance_double(Net::HTTP::Get).as_null_object }
    let(:url_shortner) { instance_double(Platform::UrlShortener).as_null_object }

    before do
      allow(Net::HTTP).to receive(:new).and_return(https)
      allow(Net::HTTP::Get).to receive(:new).and_return(request)
      allow(Platform::UrlShortener).to receive(:new).and_return(url_shortner)
    end

    context "when success" do
      let(:response) {
        double("http response", body: "statusCode=#{described_class::SUCCESS_RESPONSE_CODE};statusMessage")
      }

      before do
        allow(https).to receive(:request).with(request).and_return(response)
        subject.publish("99999", "sms content", "deliveryToken")
      end

      it { expect(https).to have_received(:request).once }
    end

    context "when error" do
      let(:status_message) { "error in sending" }
      let(:response) {
        double(
          "http response", body: "statusCode=#{described_class::SUCCESS_RESPONSE_CODE}0;statusMessage=#{status_message}"
        )
      }

      context "when timeout" do
        before do
          allow(https).to receive(:request).with(request).and_raise(Net::OpenTimeout)
        end

        it "retry the call after the first timeout" do
          expect(https).to receive(:request).twice
          expect { subject.publish("99999", "sms content", "deliveryToken") }.to raise_error(Net::OpenTimeout)
        end
      end

      context "when runtime error" do
        before do
          allow(https).to receive(:request).with(request).and_return(response)
        end

        it "raises a runtime error with the status message when the server responds with a no success code" do
          expect { subject.publish("99999", "sms content", "deliveryToken") }
            .to raise_error(RuntimeError, status_message)
        end
      end
    end
  end
end
