# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/interactors/clear_reset_password_token"
require "composites/customer/constituents/account/repositories/account_repository"

RSpec.describe Customer::Constituents::Account::Interactors::ClearResetPasswordToken do
  subject { described_class.new(account_repo: account_repo) }

  let(:account_repo) { Customer::Constituents::Account::Repositories::AccountRepository.new }
  let(:token) { "token" }

  it "returns successful result" do
    allow(account_repo).to receive(:clear_reset_password_token!).with(token).and_return(true)
    expect(subject.(token)).to be_successful
  end

  it "handles the errors from repository" do
    allow(account_repo).to receive(:clear_reset_password_token!).with(token).and_raise(account_repo.class::Error)
    expect(subject.(token)).to be_failure
  end
end
