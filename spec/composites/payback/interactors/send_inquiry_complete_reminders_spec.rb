# frozen_string_literal: true

require "rails_helper"
require "composites/payback/interactors/send_inquiry_complete_reminders"
require "composites/payback/repositories/customer_repository"
require "composites/payback/entities/customer"

RSpec.describe Payback::Interactors::SendInquiryCompleteReminders do
  subject {
    described_class.new(
      customer_repo: customer_repo
    )
  }

  let(:customer) { build(:payback_customer_entity, :accepted, accepted_at_date: 8.days.ago) }

  let(:customer_repo) do
    instance_double(
      Payback::Repositories::CustomerRepository,
      customers_to_send_inquiry_complete_reminder: [customer]
    )
  end

  before do
    allow(PaybackMailer).to receive_message_chain(:inquiry_complete_reminder, :deliver_later).and_return(true)
    allow(Payback::Logger).to receive(:info).and_return(true)
  end

  it "expects result of interactor to be Utils::Interactor::Result instance" do
    result = subject.call
    expect(result).to be_kind_of Utils::Interactor::Result
  end

  it "expects result of interactor to be successfully" do
    result = subject.call

    expect(result).to be_successful
  end

  it "finds customers to send reminder using 'customers_to_send_inquiry_complete_reminder' method on repo" do
    Timecop.freeze(Time.zone.now) do
      expect(customer_repo)
        .to receive(:customers_to_send_inquiry_complete_reminder)
        .with(
          Payback::Entities::PaybackTransaction::DEFAULT_LOCKING_INTERVAL.ago,
          described_class::INTERVAL_TO_SEND_REMINDER.ago.end_of_day,
          described_class::REMINDER_DOCUMENT_TYPE
        )

      subject.call
    end
  end

  it "initiates send of inquiry complete reminder email" do
    expect(PaybackMailer).to receive_message_chain(:inquiry_complete_reminder, :deliver_later)

    subject.call
  end

  it "logs the required information" do
    expect(Payback::Logger)
      .to receive(:info).with(a_string_matching(/sending inquiry complete reminder emails started/))
    expect(Payback::Logger)
      .to receive(:info).with(a_string_matching("sending email to customer with id #{customer.id}"))
    expect(Payback::Logger)
      .to receive(:info).with(a_string_matching(/sending inquiry complete reminder emails finished/))

    subject.call
  end

  context "when there is not any customer to send inquiry complete reminder" do
    before do
      allow(customer_repo).to receive(:customers_to_send_inquiry_complete_reminder).and_return []
    end

    it "doesn't initiate sending reminder email to any customer" do
      expect(PaybackMailer).not_to receive(:inquiry_complete_reminder)

      subject.call
    end
  end
end
