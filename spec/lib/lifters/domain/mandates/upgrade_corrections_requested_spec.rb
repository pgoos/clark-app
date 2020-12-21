# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::UpgradeCorrectionsRequested do
  let(:mandate) { double(:mandate, first_name: "FOO") }
  let(:mail) { double :mail, deliver_later: nil }

  before do
    allow(Mandate).to receive(:find).with(999).and_return(mandate)
    allow(MandateMailer).to receive(:request_corrections).and_return mail
  end

  it "sends an email" do
    expect(MandateMailer).to receive(:request_corrections).with(mandate).and_return mail
    expect(mail).to receive(:deliver_later)
    described_class.call(999)
  end

  it "sends a messenger message" do
    admin = double(:admin)
    messenger = double(:messenger, send_message: nil)

    allow(Admin).to receive(:first).and_return admin

    expect(OutboundChannels::Messenger::MessageDelivery).to \
      receive(:new).with(
        kind_of(String),
        mandate,
        admin,
        identifier: "messenger.upgrade_corrections_requested"
      ).and_return(messenger)
    described_class.call(999)
  end
end
