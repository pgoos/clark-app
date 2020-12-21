# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::ResetPasswordTokenGenerated do
  let(:email) { "sample@email" }
  let(:token) { "raw-token" }
  let(:payload) { { email: email, token: token } }
  let(:mail) { double :mail, deliver_later: nil }

  it "sends an email" do
    expect(AccountMailer).to receive(:reset_password).with(email, token).and_return mail
    expect(mail).to receive(:deliver_later)
    described_class.call(payload)
  end
end
