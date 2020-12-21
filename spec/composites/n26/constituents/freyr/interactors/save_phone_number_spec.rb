# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/interactors/save_phone_number"
require "composites/n26/constituents/freyr/entities/customer"

RSpec.describe N26::Constituents::Freyr::Interactors::SavePhoneNumber do
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
      migration_state: N26::Constituents::Freyr::Entities::Customer::State::EMAIL_VERIFIED
    )
  end

  let(:customer_repo) do
    instance_double(
      N26::Constituents::Freyr::Repositories::CustomerRepository,
      find_by_migration_token: n26_customer,
      update_migration_state: n26_customer
    )
  end

  let(:migration_token) { SecureRandom.alphanumeric(16) }
  let(:phone_number) { "+491771661372" }
  let(:phone_verification) { double(create_sms_verification: true) }
  let(:mandate) { double(id: 1) }

  before do
    allow(Platform::PhoneVerification).to receive(:new).and_return(phone_verification)
    allow(::Mandate).to receive(:find).and_return(:mandate)
  end

  it "finds customer by token" do
    expect(customer_repo).to receive(:find_by_migration_token).with(migration_token)
    subject.call(migration_token, phone_number)
  end

  it "updates migration_state to phone_added" do
    expect(customer_repo)
      .to receive(:update_migration_state)
      .with(n26_customer.id, N26::Constituents::Freyr::Entities::Customer::State::PHONE_ADDED)

    subject.call(migration_token, phone_number)
  end

  it "saves the phone number using Platform::PhoneVerification" do
    expect(phone_verification).to receive(:create_sms_verification).with(phone_number)

    subject.call(migration_token, phone_number)
  end

  it "expects result of interactor to be successfully" do
    result = subject.call(migration_token, phone_number)

    expect(result).to be_successful
  end

  it "expects result of interactor to be Utils::Interactor::Result instance" do
    result = subject.call(migration_token, phone_number)

    expect(result).to be_kind_of Utils::Interactor::Result
  end

  it "expects to return customer" do
    result = subject.call(migration_token, phone_number)

    expect(result.customer.id).to eq n26_customer.id
  end

  [
    ClarkFaker::PhoneNumber.phone_number,
    "0#{ClarkFaker::PhoneNumber.phone_number}",
    "+49#{ClarkFaker::PhoneNumber.phone_number}",
    "49#{ClarkFaker::PhoneNumber.phone_number}"
  ].each do |phone|
    it "expects result of interactor to be successful passing number #{phone}" do
      result = subject.call(migration_token, phone)

      expect(result).to be_successful
    end
  end

  context "when customer has added already phone number and it only needs to resend code" do
    before do
      allow(n26_customer).to receive(:phone_number).and_return("+491771662134")
      allow(n26_customer)
        .to receive(:migration_state).and_return(N26::Constituents::Freyr::Entities::Customer::State::PHONE_ADDED)
    end

    it "expects result of interactor to be successfully" do
      result = subject.call(migration_token, phone_number)

      expect(result).to be_successful
    end

    it "sends code using Platform::PhoneVerification" do
      expect(phone_verification).to receive(:create_sms_verification).with(n26_customer.phone_number)

      subject.call(migration_token, nil)
    end
  end

  context "when customer doesn't exist" do
    before do
      allow(customer_repo).to receive(:find_by_migration_token).and_return nil
    end

    it "returns result with failure" do
      result = subject.call(migration_token, phone_number)

      expect(result).to be_failure
    end

    it "includes the customer_not_found error" do
      result = subject.call(migration_token, phone_number)

      expect(result.errors).to include(I18n.t("account.wizards.n26.errors.customer_not_found"))
    end
  end

  context "when customer is not in eligible state" do
    before do
      allow(n26_customer).to receive(:migration_state).and_return ""
    end

    it "returns result with failure" do
      result = subject.call(migration_token, phone_number)

      expect(result).to be_failure
    end

    it "includes the customer_not_found error" do
      result = subject.call(migration_token, phone_number)

      expect(result.errors).to include(I18n.t("account.wizards.n26.errors.customer_not_eligible"))
    end
  end

  context "when phone number is not valid" do
    %w[
      smokeonthewater
      +11525905000
      491525905000123213
      01525905000
      0140745742
      1575790665
      3203336
    ].each do |phone|
      it "returns result with failure if incorrect phone #{phone} is passed" do
        result = subject.call(migration_token, phone)

        expect(result).to be_failure
      end
    end
  end

  context "when result of create_sms_verification is not successful " do
    before do
      allow(phone_verification).to receive(:create_sms_verification).and_return(false)
      allow(phone_verification).to receive(:request_error).and_return("Test Error")
    end

    it "returns result with failure" do
      result = subject.call(migration_token, phone_number)

      expect(result).to be_failure
    end
  end
end
