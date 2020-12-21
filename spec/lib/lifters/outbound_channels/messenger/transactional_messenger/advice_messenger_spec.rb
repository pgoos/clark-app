# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::AdviceMessenger do
  let!(:admin) { create(:admin) }
  let(:transactional_messenger) { OutboundChannels::Messenger::TransactionalMessenger }
  let(:message) { double("message") }

  let(:mandate) { create(:mandate) }
  let(:advice) { create(:advice, mandate: mandate, created_at: 14.days.ago) }
  let(:options) {
    {
      name:       mandate.first_name,
      product_id: advice.product_id,
      category:   advice.category_name,
      company:    advice.company_name,
      consultant: advice.admin_name
    }
  }

  it "sends advice_reminder" do
    expect(transactional_messenger).to receive(:new).with(mandate,
                                                          "advice_reminder_message_14_days",
                                                          options,
                                                          kind_of(Config::Options))
                                         .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.advice_reminder_14_days(advice)
  end

  it "sends advice_reminder_35 days" do
    expect(transactional_messenger).to receive(:new).with(mandate,
                                                          "advice_reminder_message_35_days",
                                                          options,
                                                          kind_of(Config::Options))
                                         .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.advice_reminder_35_days(advice)
  end

  it "sends reocurring advice_reminder_2_days" do
    expect(transactional_messenger).to receive(:new).with(mandate,
                                                          "reoccuring_advice_reminder_2_days",
                                                          options,
                                                          kind_of(Config::Options))
                                         .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.reocurring_advice_reminder_2_days(advice)
  end

  it "sends reocurring advice_reminder_5_days" do
    expect(transactional_messenger).to receive(:new).with(mandate,
                                                          "reoccuring_advice_reminder_5_days",
                                                          options,
                                                          kind_of(Config::Options))
                                         .and_return(message)
    expect(message).to receive(:send_message)

    transactional_messenger.reocurring_advice_reminder_5_days(advice)
  end
end
