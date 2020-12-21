# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommentMailer, :integration, type: :mailer do
  let(:admin)   { create :admin, email: email }
  let(:email)   { "admin@example.com" }
  let(:comment) { create :comment, admin: admin, commentable: admin, message: "#{admin.email} is cool" }

  describe "#admin_mention" do
    let(:mail) { CommentMailer.admin_mention(comment) }

    include_examples "checks mail rendering"

    it "does not track email in ahoy" do
      expect { mail.deliver_now }.not_to change { Ahoy::Message.count }

      expect(mail.body.encoded).not_to match(/http:\/\/test.host\/ahoy\/messages\/\w{32}\/open.gif/)
      expect(mail.body.encoded).not_to match(/ahoy\/messages/)
    end
  end
end
