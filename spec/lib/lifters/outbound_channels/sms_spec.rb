# frozen_string_literal: true

require "rails_helper"
require "lifters/outbound_channels/mocks/fake_remote_sns_client"

describe OutboundChannels::Sms do
  let(:mandate)        { double(Mandate) }
  let(:sms_text)       { Faker::Lorem.characters(number: 640) }
  let(:delivery_token) { Faker::Lorem.characters(number: 20) }
  let(:processable_phone_number) { "+4912345678900" }

  describe "#send" do
    it "sends an sms to a phone number" do
      expect(OutboundChannels::Mocks::FakeRemoteSMSClient).to receive(:publish)
      described_class.new.send_sms(processable_phone_number, sms_text, delivery_token)
    end

    it "raises argument error if unprocessable german phone number is passed" do
      unprocessable_phone_number = "911"
      subject                    = described_class.new

      expect { subject.send_sms(unprocessable_phone_number, sms_text, delivery_token) }
        .to raise_error(ArgumentError)
    end

    it "logs an error if any runtime errors gets returned from server and raise the error again" do
      exception_message = "error in sending"
      error_message =
        "Error sending sms to phone #{processable_phone_number} sms service responded with #{exception_message}"
      allow(OutboundChannels::Mocks::FakeRemoteSMSClient)
        .to receive(:publish).and_raise(RuntimeError, exception_message)
      expect(Rails.logger).to receive(:error).with(error_message)
      expect { subject.send_sms(processable_phone_number, sms_text, delivery_token) }.to raise_error(exception_message)
    end
  end
end
