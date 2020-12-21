# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderAutomation::CoverNoteMailer, :integration, type: :mailer do
  let(:documentable) { product }
  let(:recipient) { "john.doe@example.com" }
  let(:mandate) { create :mandate, state: :created, user: user }
  let(:product) { create :product, mandate: mandate}
  let(:admin) { double(full_name: "Jane Doe") }
  let(:user) { create :user, subscriber: true }

  describe "#cover_note" do
    let(:mail) { OrderAutomation::CoverNoteMailer.cover_note(product, admin, recipient) }
    let(:document_type) { DocumentType.deckungsnote_email }

    include_examples "checks mail rendering" do
      let(:html_part) { admin.full_name }
    end

    include_examples "send out an email if mandate belongs to the partner"
    include_examples "sends out an email when user is subscriber"
    include_examples "tracks document and mandate in ahoy email"
  end
end

