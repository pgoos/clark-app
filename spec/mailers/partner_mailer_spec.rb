# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerMailer, :integration, type: :mailer do
  let(:mandate) { create :mandate, lead: lead, owner_ident: partner.ident }
  let(:lead) { create :lead, email: email }
  let(:email) { "test@test.com" }

  describe "#partner_greeting" do
    let(:document_type) { DocumentType.partner_greeting }
    let(:document) { create :document, documentable: opportunity, document_type: document_type }
    let(:mail) { PartnerMailer.partner_greeting(mandate) }
    let(:documentable) { mandate }

    before do
      allow_any_instance_of(OutboundChannels::DeliveryPermission).to receive(:interaction_allowed_for?).and_return(true)
    end

    context "partner is active" do
      let(:partner) { create :partner, :active }

      include_examples "checks mail rendering"
      include_examples "tracks document and mandate in ahoy email"
    end

    context "partner is inactive" do
      let(:partner) { create :partner, :inactive }

      it "does not send out an email" do
        mail.deliver_now
        expect(ActionMailer::Base.deliveries.count).to eq(0)
        ActionMailer::Base.deliveries.clear
      end
    end
  end
end
