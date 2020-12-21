# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::PlaceholderMessenger do
  let!(:admin) { create(:admin) }
  let(:transactional_messenger) { OutboundChannels::Messenger::TransactionalMessenger }
  let(:message) { double("message") }

  let(:mandate) { create(:mandate) }
  let(:inquiry) { create(:inquiry, mandate: mandate, categories: [category]) }
  let(:category) { create(:category) }
  let(:options) {
    {
      name:     mandate.first_name,
      category: category
    }
  }

  it "sends placeholder_reminder" do
    expect(transactional_messenger).to receive(:new)
      .with(mandate, "placeholder_reminder", options, kind_of(Config::Options))
      .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.placeholder_reminder(mandate, category)
  end
end
