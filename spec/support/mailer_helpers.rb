# Clears Action Mailer deliveries before each spec.
module MailerHelpers
  def emails
    ActionMailer::Base.deliveries
  end

  def last_email
    emails.last
  end

  def expect_document_tracked_in_ahoy_emails(documentable, document_type, mandate)
    message = Ahoy::Message.last
    expect(message.user).to eq(mandate)
    expect(message.document_type).to eq(document_type.id.to_s)
    expect([documentable.id, mandate.id]).to include(message.documentable_id)
    expect([documentable.class.to_s, mandate.class.to_s]).to include(message.documentable_type)
  end
end

RSpec.configure do |config|
  config.include MailerHelpers, type: :mailer
end
