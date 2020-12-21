# frozen_string_literal: true

require "rails_helper"

describe OutboundChannels::Sovendus do
  let(:mandate) { create(:mandate) }
  let(:subject) { described_class.new(mandate) }
  let(:sovendus_request_token) { "123456" }

  describe "#send_sovendus_call" do
    context "with mandate not having a request token" do
      it "returns instantly when mandate doesn't have a sovendus request token" do
        subject.send_sovendus_call
        expect(OutboundChannels::Mocks::FakeSovendusClient).not_to receive(:publish)
      end
    end

    context "with mandate having a request token" do
      before do
        mandate.info[described_class::SOVENDUS_TOKEN_ATTR_NAME] = sovendus_request_token
        mandate.save
      end

      it "call the sovendus client publish method with the sovendus request token when found in the mandate info" do
        expect(OutboundChannels::Mocks::FakeSovendusClient).to receive(:publish).with(sovendus_request_token)
        subject.send_sovendus_call
      end

      it "logs any errors in sending sending them to sentry and doesn't propagate these errors higher" do
        error_message = "error"
        allow(OutboundChannels::Mocks::FakeSovendusClient).to receive(:publish).and_raise(error_message)
        expect(Raven).to receive(:capture_exception)
        subject.send_sovendus_call
      end
    end
  end
end
