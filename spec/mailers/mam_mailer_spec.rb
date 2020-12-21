# frozen_string_literal: true

require "rails_helper"

RSpec.describe MamMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, user: create(:user), state: :created }

  describe "#crediting_email" do
    let(:mail) { MamMailer.crediting_email(mandate) }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.crediting_email }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end
end
