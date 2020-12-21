# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutboundChannels::Messenger::MessageRelay, type: :integration do
  let(:message_delivery) { OutboundChannels::Messenger::MessageDelivery }
  let(:user)             { create(:user, :with_mandate) }
  let(:admin)            { create(:admin) }
  let(:content)          { Faker::Lorem.characters(50) }
  let(:device)           { create(:device) }
  let(:subject)          { described_class.new(content, user.mandate, admin) }

  describe "#acknowledge_message" do
    let(:message)         { OpenStruct.new }
    let(:admin)           { double(Admin) }
    let(:mandate)         { double(Mandate) }
    let(:metadata)        { {} }
    let(:content)         { "some message" }
    let(:delivery_double) { n_double("delivery_double") }

    before do
      message.content  = content
      message.admin    = admin
      message.mandate  = mandate
      message.metadata = metadata
    end

    it "sets a delivery with the message content" do
      expect(message_delivery).to receive(:new)
        .with(content, mandate, admin, metadata)
        .and_return(delivery_double)

      allow(delivery_double).to receive(:call_socket_api).with(message)
      described_class.confirm_message_via_socket(message)
    end

    it "sends the message via socket" do
      allow(message_delivery).to receive(:new).and_return(delivery_double)
      expect(delivery_double).to receive(:call_socket_api).with(message)
      described_class.confirm_message_via_socket(message)
    end

    context "confirm_message_via_socket" do
      it "sets a delivery with the message content" do
        expect(message_delivery).to receive(:new)
          .with(content, mandate, admin, metadata)
          .and_return(delivery_double)
        allow(delivery_double).to receive(:send_custom_message).with(message, Config::Options)

        described_class.pass_message(message)
      end

      it "sends the message via socket" do
        allow(message_delivery).to receive(:new).and_return(delivery_double)
        expect(delivery_double).to receive(:send_custom_message).with(message, Config::Options)

        described_class.pass_message(message)
      end

      it "sends the message via socket with push sms disabled" do
        allow(message_delivery).to receive(:new).and_return(delivery_double)
        expect(delivery_double).to receive(:send_custom_message).with(message, push_with_sms_fallback: true)

        described_class.pass_message(message, push_with_sms_fallback: true)
      end
    end
  end
end
