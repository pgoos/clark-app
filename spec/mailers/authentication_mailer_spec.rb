# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthenticationMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, user: user, state: :created }
  let(:user)     { create :user, email: email, subscriber: true }
  let(:email)    { "whitfielddiffie@gmail.com" }
  let(:token)    { "token" }

  describe "#confirmation_instructions" do
    let(:mail) { AuthenticationMailer.confirmation_instructions(user, token) }

    include_examples "checks mail rendering"

    describe "with ahoy email tracking" do
      it "includes the tracking pixel" do
        expect(mail.body.encoded).to match(/open.gif/)
      end

      it "replaces links with tracking links", skip: "Failing because of changed encoding" do
        original_link       = "https://www.facebook.com/ClarkGermany"
        tracking_parameters = "utm_campaign=confirmation_instructions&utm_medium=email&utm_source=authentication_mailer"
        tracking_link       = /http:\/\/test.host\/ahoy\/messages\/\w{32}\/click\?signature=\w{40}&amp;url=#{CGI.escape(original_link + "?" + tracking_parameters)}/
        expect(mail.body.encoded).to include(tracking_link)
      end

      it "stores a message object upon delivery" do
        expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)

        message = Ahoy::Message.last
        expect(message.to).to eq(email)
        expect(message.token).to match(/\w{32}/)

        expect(message.mailer).to eq("AuthenticationMailer#confirmation_instructions")

        expect(message.utm_medium).to eq("email")
        expect(message.utm_source).to eq("authentication_mailer")
        expect(message.utm_campaign).to eq("confirmation_instructions")
      end

      it "tracks mandate in ahoy email" do
        expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
        expect_mandate_tracked_in_ahoy_email(mandate)
      end
    end
  end

  describe "#reset_password_instructions" do
    let(:mail) { AuthenticationMailer.reset_password_instructions(user, token) }

    include_examples "checks mail rendering"

    it "does not track mandate in ahoy email because it breaks the mobile apps" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(0)
    end
  end

  describe "#password_change" do
    let(:mail) { AuthenticationMailer.password_change(user) }

    include_examples "checks mail rendering"

    it "tracks mandate in ahoy email" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
      expect_mandate_tracked_in_ahoy_email(mandate)
    end
  end

  def expect_mandate_tracked_in_ahoy_email(mandate)
    message = Ahoy::Message.last
    expect(message.user).to eq(mandate)
  end
end
