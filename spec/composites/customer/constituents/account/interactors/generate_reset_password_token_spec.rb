# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/interactors/generate_reset_password_token"

RSpec.describe Customer::Constituents::Account::Interactors::GenerateResetPasswordToken do
  subject do
    described_class.new(
      account_repo: account_repo,
      emit_event: emit_event
    )
  end

  let(:account_repo) { double :repo }
  let(:emit_event) { double :emitter }
  let(:token) { "valid-token" }
  let(:email) { "customer@sample" }
  let(:payload) { { email: email, token: token } }
  let(:result) { subject.(email) }

  context "when email is valid" do
    it "generates token and sends email" do
      expect(account_repo).to receive(:generate_reset_password_token).with(email).and_return(token)
      expect(emit_event).to receive(:call).with(:reset_password_token_generated, payload)
      expect(result).to be_successful
    end
  end

  context "when email is invalid" do
    it "does nothing" do
      expect(account_repo).to receive(:generate_reset_password_token).with(email).and_return(nil)
      expect(emit_event).not_to receive(:call)
      expect(result).to be_successful
    end
  end
end
