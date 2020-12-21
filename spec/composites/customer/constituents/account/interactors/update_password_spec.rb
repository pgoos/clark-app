# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/interactors/update_password"

RSpec.describe Customer::Constituents::Account::Interactors::UpdatePassword do
  subject { described_class.new(account_repo: account_repo, validate: validate) }

  let(:account_repo) { double :repo, update!: true }
  let(:validate) { ->(_) { double(:result, failure?: false) } }

  it "updates password on account" do
    expect(account_repo).to receive(:update!).with(999, password: "PSW")
    result = subject.(999, "PSW")
    expect(result).to be_successful
  end

  context "when password is invalid" do
    let(:validate) { ->(_) { double(:result, failure?: true, errors: { password: "is invalid" }) } }

    it "returns an error" do
      result = subject.(999, "PSW")
      expect(result).to be_failure
      expect(result.errors).to eq [{ password: "is invalid" }]
    end
  end
end
