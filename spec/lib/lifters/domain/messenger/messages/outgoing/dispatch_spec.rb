# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::Messages::Outgoing::Dispatch, :integration do
  let(:message) { build :interaction_message, mandate: create(:mandate) }

  it "saves the record" do
    described_class.(message)

    expect(message).to be_persisted
  end

  it "sends the message to customer" do
    expect(OutboundChannels::Messenger::MessageRelay).to \
      receive(:pass_message).with(kind_of(Interaction::Message), push_with_sms_fallback: true)

    described_class.(message)
  end
end
