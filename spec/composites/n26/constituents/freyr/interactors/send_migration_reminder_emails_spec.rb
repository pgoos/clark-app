# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/interactors/send_migration_reminder_emails"
require "composites/n26/constituents/freyr/entities/customer"

RSpec.describe N26::Constituents::Freyr::Interactors::SendMigrationReminderEmails do
  subject {
    described_class.new(
      customer_repo: customer_repo
    )
  }

  let(:migration_token) { SecureRandom.alphanumeric(16) }

  let(:n26_customer) do
    double(
      N26::Constituents::Freyr::Entities::Customer,
      id: 1,
      owner_ident: "n26",
      migration_state: N26::Constituents::Freyr::Entities::Customer::State::PHONE_VERIFIED,
      migration_token: migration_token
    )
  end

  let(:customer_repo) do
    instance_double(
      N26::Constituents::Freyr::Repositories::CustomerRepository,
      customers_to_send_reminder: [n26_customer]
    )
  end

  before do
    allow(N26Mailer).to receive_message_chain(:migration_reminder, :deliver_later).and_return(true)
    allow(N26::Logger).to receive(:info).and_return(true)
  end

  it "expects result of interactor to be Utils::Interactor::Result instance" do
    result = subject.call
    expect(result).to be_kind_of Utils::Interactor::Result
  end

  it "expects result of interactor to be successfully" do
    result = subject.call

    expect(result).to be_successful
  end

  it "finds customers to send reminder using 'customers_to_send_reminder' method on repo " do
    expect(customer_repo)
      .to receive(:customers_to_send_reminder).with(described_class::DAYS_INTERVAL_TO_SEND_REMINDER.days.ago.end_of_day,
                                                    described_class::MIGRATION_REMINDER_DOCUMENT_TYPE)

    subject.call
  end

  it "initiates send of migration reminder email" do
    expect(N26Mailer)
      .to receive_message_chain(:migration_reminder, :deliver_later)

    subject.call
  end

  it "logs the required information" do
    expect(N26::Logger)
      .to receive(:info).with(a_string_matching(/reminder emails started/))
    expect(N26::Logger)
      .to receive(:info).with(a_string_matching("sending email to customer with id #{n26_customer.id}"))
    expect(N26::Logger)
      .to receive(:info).with(a_string_matching(/reminder emails finished/))

    subject.call
  end

  context "when there is not any customer to send migration reminder" do
    before do
      allow(customer_repo).to receive(:customers_to_send_reminder).and_return []
    end

    it "doesn't initiate sending migration reminder email to any customer" do
      expect(N26Mailer).not_to receive(:migration_reminder)

      subject.call
    end
  end
end
