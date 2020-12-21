# frozen_string_literal: true

require "rails_helper"

RSpec.describe FakeNotificationMailer, :integration, type: :mailer do
  let(:name)    { "Name" }
  let(:method)  { "Method" }
  let(:context) { {message: nil} }

  describe "#notify_about_push" do
    let(:inquiry) { create :inquiry, mandate: mandate }
    let(:mail)    { FakeNotificationMailer.notify_about_push(name, method, context) }

    it "renders the email successfully" do
      expect(mail.subject).to match("Clark: New push message")
      expect(mail.body.encoded).to match("We got a new message")
    end

    it "does not track email in ahoy" do
      expect { mail.deliver_now }.not_to change { Ahoy::Message.count }

      expect(mail.body.encoded).not_to match(/http:\/\/test.host\/ahoy\/messages\/\w{32}\/open.gif/)
      expect(mail.body.encoded).not_to match(/ahoy\/messages/)
    end
  end

  describe "#notify_about_sms" do
    let(:inquiry) { create :inquiry, mandate: mandate }
    let(:mail)    { FakeNotificationMailer.notify_about_sms(name, method, context) }

    it "renders the email successfully" do
      expect(mail.subject).to match("Clark: New SMS message")
      expect(mail.body.encoded).to match("We got a new message")
    end

    it "does not track email in ahoy" do
      expect { mail.deliver_now }.not_to change { Ahoy::Message.count }

      expect(mail.body.encoded).not_to match(/http:\/\/test.host\/ahoy\/messages\/\w{32}\/open.gif/)
      expect(mail.body.encoded).not_to match(/ahoy\/messages/)
    end
  end
end
