# frozen_string_literal: true

require "rails_helper"

RSpec.describe StarterMailer, :integration, type: :mailer do
  describe "#new_starter" do
    let(:starter) { "" }
    let(:url)     { "" }
    let(:mail)    { StarterMailer.new_starter(starter, url) }

    it "renders the email successfully" do
      expect(mail.subject).to eq("Neuer Lead")
      expect(mail.body.encoded).to match("Name")
      expect(mail.to).to eq(["service@clark.de"])
    end

    it "does not track email in ahoy" do
      expect { mail.deliver_now }.not_to change { Ahoy::Message.count }

      expect(mail.body.encoded)
        .not_to match(/http:\/\/test.host\/ahoy\/messages\/\w{32}\/open.gif/)

      expect(mail.body.encoded)
        .not_to match(/ahoy\/messages/)
    end
  end
end
