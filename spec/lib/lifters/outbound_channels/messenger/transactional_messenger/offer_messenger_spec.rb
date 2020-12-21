# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::OfferMessenger do
  let!(:admin) { create(:admin) }
  let(:transactional_messenger) { OutboundChannels::Messenger::TransactionalMessenger }
  let(:message) { double("message") }

  let(:mandate) { create(:mandate) }
  let(:offer) { create(:active_offer, mandate: mandate) }
  let(:category) { create(:category) }
  let(:options) {
    {
      name:                mandate.first_name,
      category_name:       offer.category.name,
      recommended_company: offer.recommended_option.product.company.name,
      offer_id:            offer.id,
    }
  }

  it "sends offer_available" do
    expect(transactional_messenger).to receive(:new).with(mandate, "offer_available", options)
                                         .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.offer_available(offer)
  end

  it "sends offer_reminder" do
    expect(transactional_messenger).to receive(:new).with(mandate, "offer_reminder", options)
                                         .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.offer_reminder(offer)
  end
end
