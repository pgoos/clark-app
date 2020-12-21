# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Campaigns::Kfz::Messenger do
  let!(:admin) { create(:admin) }
  let(:transactional_messenger) { OutboundChannels::Messenger::TransactionalMessenger }
  let(:message) { double("message") }

  let(:mandate) { create(:mandate) }
  let(:options) {
    {
      name: mandate.first_name
    }
  }

  before do
    transactional_messenger.extend described_class
  end

  it "sends offer_available" do
    expect(transactional_messenger).to receive(:new).with(mandate, "kfz_campaign_2018", options)
                                                    .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.send_campaign_message(mandate)
  end
end
