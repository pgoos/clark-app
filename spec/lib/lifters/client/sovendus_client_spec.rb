# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutboundChannels::Clients::SovendusClient do
  let(:sovendus_api_key) { "123456" }
  let(:sovendus_product_id) { "987654" }
  let(:sovendus_end_point) { "https://localhost" }

  before do
    allow(Settings).to receive_message_chain(:sovendus, :api_key).and_return(sovendus_api_key)
    allow(Settings).to receive_message_chain(:sovendus, :product_id).and_return(sovendus_product_id)
    allow(Settings).to receive_message_chain(:sovendus, :end_point).and_return(sovendus_end_point)
  end

  describe "#initialize" do
    it "creates instance variable sovendus_api_key and assign the settings value to it" do
      expect(subject.instance_variable_get(:@sovendus_api_key)).to eq(sovendus_api_key)
    end

    it "creates instance variable sovendus_product_id and assign the settings value to it" do
      expect(subject.instance_variable_get(:@sovendus_product_id)).to eq(sovendus_product_id)
    end

    it "creates instance variable sovendus_end_point and assign the settings value to it" do
      expect(subject.instance_variable_get(:@sovendus_end_point)).to eq(sovendus_end_point)
    end
  end

  describe "#publish" do
    let(:sovendus_request_token) { "sov-token" }

    context "when success" do
      let(:response) {
        double("http response", code: HTTP::Status::OK, body: "{message: success}")
      }

      before do
        allow(subject).to receive(:build_sovendus_request).and_return(response)
      end

      it "doesn't raise any exceptions if API call succeed" do
        expect { subject.publish(sovendus_request_token) }.not_to raise_error
      end
    end

    context "when error" do
      let(:api_response_message) { "{message: error}" }
      let(:response) {
        double("http response", code: HTTP::Status::BAD_REQUEST, body: api_response_message)
      }

      before do
        allow(subject).to receive(:build_sovendus_request).and_return(response)
      end

      it "raises an exception with the message returned from the API response" do
        expect { subject.publish(sovendus_request_token) }.to raise_error(api_response_message)
      end

      context "when timeout" do
        before do
          allow(subject).to receive(:build_sovendus_request).and_raise(Net::OpenTimeout)
        end

        it "retry the call after the first timeout" do
          expect(subject).to receive(:build_sovendus_request).twice
          expect { subject.publish(sovendus_request_token) }.to raise_error(Net::OpenTimeout)
        end
      end
    end
  end
end
