# frozen_string_literal: true

require "rails_helper"

RSpec.describe MalburgMailer, :integration, type: :mailer do
  let(:mandate) { create :mandate, lead: lead }
  let(:lead) { create :lead, email: email}
  let(:email) { "IAmIronMan@daaadaaadadada.com" }
  let(:documentable) { mandate }

  describe "#clark_greeting" do
    let(:mail) { MalburgMailer.clark_greeting(mandate) }
    let(:document_type) { DocumentType.clark_greeting }

    describe "delivers the mail correctly if source of the lead is malburg" do
      before do
        lead.source_data = {"adjust": {"network": "Malburg"}}
        lead.save!
      end

      include_examples "checks mail rendering"
      include_examples "stores a message object upon delivery", "MalburgMailer#clark_greeting", "malburg_mailer", "clark_greeting"
      include_examples "tracks document and mandate in ahoy email"
    end

    describe "does not deliver the email if source of the lead is not malburg" do
      it 'stores a message object upon delivery' do
        expect{ mail.deliver_now }.not_to change{ Ahoy::Message.count }
      end
    end
  end

  describe "#malburg_mailer_fb_malburg_greeting" do
    let(:mail) { MalburgMailer.fb_malburg_greeting(mandate) }
    let(:document_type) { DocumentType.fb_malburg_greeting }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end
end
