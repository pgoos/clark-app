# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, user: user, state: :created }
  let(:user) { create :user, email: email, subscriber: true }
  let(:email) { "new@super-user.com" }
  let(:documentable) { mandate }

  describe "#reset_password" do
    let(:mail) { AccountMailer.reset_password(mandate.email, "token") }
    let(:document_type) { DocumentType.reset_password }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"

    context "case insensitive email" do
      let(:mail) { AccountMailer.reset_password("New@super-User.com", "token") }

      include_examples "checks mail rendering"
    end
  end
end
