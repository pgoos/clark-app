# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/interactors/update_password"
require "composites/n26/constituents/freyr/entities/customer"

RSpec.describe N26::Constituents::Freyr::Interactors::UpdatePassword do
  subject {
    described_class.new(
      customer_repo: customer_repo
    )
  }

  let(:n26_customer) do
    double(
      N26::Constituents::Freyr::Entities::Customer,
      id: 1,
      owner_ident: "n26",
      migration_state: N26::Constituents::Freyr::Entities::Customer::State::PHONE_VERIFIED,
      owned_by_n26?: true
    )
  end

  let(:customer_repo) do
    instance_double(
      N26::Constituents::Freyr::Repositories::CustomerRepository,
      find_by_migration_token: n26_customer,
      clear_migration_token!: true,
      update!: true,
      update_migration_state: n26_customer,
      update_account_password!: true
    )
  end

  let(:password) { "Test12345." }
  let(:clark_ident) { described_class::CLARK_IDENT }
  let(:migration_token) { SecureRandom.alphanumeric(16) }

  before do
    allow(N26Mailer).to receive_message_chain(:migration_welcome, :deliver_later).and_return(true)
  end

  it "finds customer by token" do
    expect(customer_repo).to receive(:find_by_migration_token).with(migration_token)
    subject.call(migration_token, password)
  end

  it "updates migration_state to migrated" do
    expect(customer_repo)
      .to receive(:update_migration_state)
      .with(n26_customer.id, N26::Constituents::Freyr::Entities::Customer::State::MIGRATED)

    subject.call(migration_token, password)
  end

  it "clears the migration_token" do
    expect(customer_repo)
      .to receive(:clear_migration_token!).with(n26_customer.id)

    subject.call(migration_token, password)
  end

  it "updates customer's account password" do
    expect(customer_repo)
      .to receive(:update_account_password!).with(n26_customer.id, password)

    subject.call(migration_token, password)
  end

  it "changes the ownership of customer" do
    expect(customer_repo)
      .to receive(:update!).with(n26_customer.id, owner_ident: clark_ident, accessible_by: [clark_ident])

    subject.call(migration_token, password)
  end

  it "expects result of interactor to be successfully" do
    result = subject.call(migration_token, password)

    expect(result).to be_successful
  end

  it "expects result of interactor to be Utils::Interactor::Result instance" do
    result = subject.call(migration_token, password)
    expect(result).to be_kind_of Utils::Interactor::Result
  end

  it "expects to return customer" do
    result = subject.call(migration_token, password)
    expect(result.customer.id).to eq n26_customer.id
  end

  it "sends migration welcome email" do
    expect(N26Mailer).to receive_message_chain(:migration_welcome, :deliver_later)

    subject.call(migration_token, password)
  end

  context "when customer doesn't exist" do
    before do
      allow(customer_repo).to receive(:find_by_migration_token).and_return nil
    end

    it "returns result with failure" do
      result = subject.call(migration_token, password)

      expect(result).to be_failure
    end

    it "includes the customer_not_found error" do
      result = subject.call(migration_token, password)

      expect(result.errors).to include(I18n.t("account.wizards.n26.errors.customer_not_found"))
    end
  end

  context "when customer is not in eligible state" do
    before do
      allow(n26_customer).to receive(:migration_state).and_return "phone_added"
    end

    it "returns result with failure" do
      result = subject.call(migration_token, password)

      expect(result).to be_failure
    end

    it "includes the not_eligible error" do
      result = subject.call(migration_token, password)

      expect(result.errors).to include(I18n.t("account.wizards.n26.errors.customer_not_eligible"))
    end
  end

  context "when password complexity is not valid" do
    let(:password) { "1234" }

    it "returns result with failure" do
      result = subject.call(migration_token, password)

      expect(result).to be_failure
    end
  end

  context "when the customer is not owned by n26" do
    before do
      allow(n26_customer).to receive(:owned_by_n26?).and_return(false)
    end

    it "returns result with failure" do
      result = subject.call(migration_token, password)

      expect(result).to be_failure
    end

    it "includes the not_eligible error" do
      result = subject.call(migration_token, password)

      expect(result.errors).to include(I18n.t("account.wizards.n26.errors.customer_not_eligible"))
    end
  end
end
