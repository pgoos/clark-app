# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::PortfolioMessenger do
  let!(:admin) { create(:admin) }
  let(:transactional_messenger) { OutboundChannels::Messenger::TransactionalMessenger }
  let(:message) { double("message") }

  let(:mandate) { create(:mandate) }
  let(:inquiry) { create(:inquiry, mandate: mandate, categories: [category]) }
  let(:category) { create(:category) }
  let(:options) {
    {
      name:            inquiry.mandate.first_name,
      inquiry_id:      inquiry.id,
      category_indent: inquiry.categories.first.ident
    }
  }

  it "sends portfolio_in_progress" do
    expect(transactional_messenger).to receive(:new)
      .with(mandate, "portfolio_in_progress", options, kind_of(Config::Options))
      .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.portfolio_in_progress(inquiry)
  end

  it "sends portfolio_in_progress" do
    expect(transactional_messenger).to receive(:new)
      .with(mandate, "portfolio_in_progress_4weeks", options, kind_of(Config::Options))
      .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.portfolio_in_progress_4weeks(inquiry)
  end

  it "sends portfolio_in_progress" do
    expect(transactional_messenger).to receive(:new)
      .with(mandate, "portfolio_in_progress_16weeks", options, kind_of(Config::Options))
      .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.portfolio_in_progress_16weeks(inquiry)
  end
end
