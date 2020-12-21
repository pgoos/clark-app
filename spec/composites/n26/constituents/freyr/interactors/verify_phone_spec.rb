# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/interactors/verify_phone"
require "composites/n26/constituents/freyr/entities/customer"

RSpec.describe N26::Constituents::Freyr::Interactors::VerifyPhone do
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
      migration_state: N26::Constituents::Freyr::Entities::Customer::State::PHONE_ADDED
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
  let(:verification_token) { SecureRandom.random_number((1_000...10_000)).to_s }
  let(:phone_verification) { double(verify_token: true) }
  let(:mandate) { double(id: 1) }

  before do
    allow(Platform::PhoneVerification).to receive(:new).and_return(phone_verification)
    allow(::Mandate).to receive(:find).and_return(:mandate)
  end

  it "finds customer by token" do
    expect(customer_repo).to receive(:find_by_migration_token).with(migration_token)
    subject.call(migration_token, verification_token)
  end

  it "updates migration_state to phone_verified" do
    expect(customer_repo)
      .to receive(:update_migration_state)
      .with(n26_customer.id, N26::Constituents::Freyr::Entities::Customer::State::PHONE_VERIFIED)

    subject.call(migration_token, verification_token)
  end

  it "verifies the verification code using Platform::PhoneVerification" do
    expect(phone_verification).to receive(:verify_token).with(verification_token)

    subject.call(migration_token, verification_token)
  end

  it "expects result of interactor to be successfully" do
    result = subject.call(migration_token, verification_token)

    expect(result).to be_successful
  end

  it "expects result of interactor to be Utils::Interactor::Result instance" do
    result = subject.call(migration_token, verification_token)
    expect(result).to be_kind_of Utils::Interactor::Result
  end

  it "expects to return customer" do
    result = subject.call(migration_token, verification_token)
    expect(result.customer.id).to eq n26_customer.id
  end

  context "when customer doesn't exist" do
    before do
      allow(customer_repo).to receive(:find_by_migration_token).and_return nil
    end

    it "returns result with failure" do
      result = subject.call(migration_token, verification_token)

      expect(result).to be_failure
    end

    it "includes the customer_not_found error" do
      result = subject.call(migration_token, verification_token)

      expect(result.errors).to include(I18n.t("account.wizards.n26.errors.customer_not_found"))
    end
  end

  context "when customer is not in eligible state" do
    before do
      allow(n26_customer).to receive(:migration_state).and_return "email_verified"
    end

    it "returns result with failure" do
      result = subject.call(migration_token, verification_token)

      expect(result).to be_failure
    end

    it "includes the customer_not_found error" do
      result = subject.call(migration_token, verification_token)

      expect(result.errors).to include(I18n.t("account.wizards.n26.errors.customer_not_eligible"))
    end
  end

  context "when result of verify_token is not successful " do
    before do
      allow(phone_verification).to receive(:verify_token).and_return(false)
      allow(phone_verification).to receive(:bad_token_error).and_return("Verification token is not correct")
    end

    it "returns result with failure" do
      result = subject.call(migration_token, verification_token)

      expect(result).to be_failure
    end
  end
end
