# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/interactors/verify_reset_password_token"

RSpec.describe Customer::Constituents::Account::Interactors::VerifyResetPasswordToken do
  subject do
    described_class.new(
      account_repo: account_repo
    )
  end

  let(:account_repo) { double :repo, find_by_reset_password_token: account }
  let(:account) { double(:account, reset_password_sent_at: sent_at) }
  let(:sent_at) { Time.now - (described_class::EXPIRATION_TIME + difference) }
  let(:difference) { 0 }
  let(:result) { subject.call(token) }
  let(:token) { "some-tokenn" }

  before { Timecop.freeze(Time.current) }

  after  { Timecop.return }

  context "without matching account" do
    let(:account) { nil }

    it "returns not found error" do
      expect(result).to be_failure
      expect(result.errors[0]).to eql(I18n.t("errors.messages.not_found"))
      expect(result.account).to eql(account)
    end
  end

  context "with an expired token" do
    let(:difference) { 1.seconds }

    it "returns expired error" do
      expect(result).to be_failure
      expect(result.errors[0]).to eql(I18n.t("errors.messages.expired"))
      expect(result.account).to eql(account)
    end
  end

  context "with a nil sent_at" do
    let(:difference) { -1.seconds }
    let(:account) { double(:account, reset_password_sent_at: nil) }

    it "returns expired error" do
      expect(result).to be_failure
      expect(result.errors[0]).to eql(I18n.t("errors.messages.expired"))
      expect(result.account).to eql(account)
    end
  end

  context "with a valid token" do
    let(:difference) { -1.seconds }

    it "is successful" do
      expect(result).to be_successful
      expect(result.account).to eql(account)
    end
  end
end
