# frozen_string_literal: true

require "rails_helper"

RSpec.describe MandateMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, user: user, state: :created }
  let(:user) { create :user, email: email, subscriber: true }
  let(:email) { "whitfielddiffie@gmail.com" }
  let(:documentable) { mandate }

  describe "#greeting" do
    let(:mail) { MandateMailer.greeting(mandate) }
    let(:document_type) { DocumentType.greeting }

    describe "with ahoy email tracking" do
      it "includes the tracking pixel" do
        expect(mail.body.encoded).to match(/open\.gif/)
      end

      it "replaces links with tracking links" do
        expect(mail.body.encoded).to match(/click\?signature/)
      end

      include_examples "checks mail rendering"
      it_behaves_like "stores a message object upon delivery", "MandateMailer#greeting", "mandate_mailer", "greeting"
      it_behaves_like "tracks document and mandate in ahoy email"
      it_behaves_like "does not send out an email if mandate belongs to the partner"
    end
  end

  describe "#greeting mail 1822direkt" do
    let(:user) {
      create :user, email: email,
                    subscriber: true,
                    source_data: { "adjust": { "network": "1822direkt" } }
    }

    let!(:mandate) { create :mandate, user: user, state: :created }
    let(:mail)     { MandateMailer.greeting_1822direkt(mandate) }
    let(:email)    { "whitfielddiffie@gmail.com" }

    include_examples "checks mail rendering"
    describe "Delivers the mail correctly." do
      # rubocop:disable Layout/LineLength
      it_behaves_like "stores a message object upon delivery", "MandateMailer#greeting_1822direkt", "mandate_mailer", "greeting_1822direkt"
      # rubocop:enable Layout/LineLength
    end
  end

  describe "#greeting Miles and More" do
    let(:user) {
      create :user, email: email,
                    subscriber: true,
                    source_data: { "adjust": { "network": "mam" } }
    }
    let!(:mandate) { create :mandate, user: user, state: :created }
    let(:mail)     { MandateMailer.greeting_mam(mandate) }

    include_examples "checks mail rendering"
    describe "Delivers the mail correctly." do
      it_behaves_like "stores a message object upon delivery", "MandateMailer#greeting_mam", "mandate_mailer", "greeting_mam"
    end
  end

  describe "#greeting Primoco" do
    let(:mail) { MandateMailer.greeting_primoco(mandate) }

    include_examples "checks mail rendering"
    describe "Delivers the mail correctly." do
      it_behaves_like "stores a message object upon delivery", "MandateMailer#greeting_primoco", "mandate_mailer", "greeting_primoco"
    end
  end

  describe "#greeting Payback" do
    let(:mail) { MandateMailer.greeting_payback(mandate) }

    include_examples "checks mail rendering"
    describe "Delivers the mail correctly." do
      it_behaves_like "stores a message object upon delivery",
                      "MandateMailer#greeting_payback",
                      "mandate_mailer",
                      "greeting_payback"
    end
  end

  describe "#confirmation_reminder" do
    let(:mail)  { MandateMailer.confirmation_reminder(mandate, token) }
    let(:token) { "confirmation_token" }
    let(:document_type) { DocumentType.confirmation_reminder }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#inactive_customer" do
    let(:mail) { MandateMailer.inactive_customer(mandate) }
    let(:document_type) { DocumentType.inactive_customer }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#reminder" do
    let(:mail) { MandateMailer.reminder(mandate) }
    let(:document_type) { DocumentType.reminder }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#reminder2" do
    let(:mail) { MandateMailer.reminder2(mandate) }
    let(:document_type) { DocumentType.reminder2 }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#reminder3" do
    let(:mail) { MandateMailer.reminder3(mandate) }
    let(:document_type) { DocumentType.reminder3 }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#request_corrections" do
    let(:mail) { MandateMailer.request_corrections(mandate) }
    let(:document_type) { DocumentType.request_corrections }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#revoke_customer" do
    let(:mail) { MandateMailer.revoke_customer(mandate) }
    let(:document_type) { DocumentType.revoke_customer }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#revoke_not_accepted_customer" do
    let(:mail) { MandateMailer.revoke_not_accepted_customer(mandate) }
    let(:document_type) { DocumentType.revoke_not_accepted_customer }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#revoke_partner_customer" do
    let(:mail) { MandateMailer.revoke_partner_customer(mandate) }
    let(:document_type) { DocumentType.revoke_partner_customer }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#revoke_n26_customer" do
    let(:mail) { MandateMailer.revoke_n26_customer(mandate) }
    let(:document_type) { DocumentType.revoke_n26_customer }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#customer_has_been_unsubscribed" do
    let(:mail) { MandateMailer.customer_has_been_unsubscribed(mandate) }
    let(:document_type) { DocumentType.customer_has_been_unsubscribed }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#rate_clark" do
    let(:mail) { MandateMailer.rate_clark(mandate) }
    let(:document_type) { DocumentType.rate_clark }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#raffle_confirmation" do
    let(:mail) { MandateMailer.raffle_confirmation(mandate) }
    let(:document_type) { DocumentType.raffle_confirmation }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#change_address_notification" do
    let(:address) { build :address, city: "Abcde", mandate: mandate }
    let(:old_address) { build :address, city: "Abcde", mandate: mandate }
    let(:product) {
      build :product, state: "under_management",
                      contract_ended_at: 1.day.ago,
                      renewal_period: nil,
                      mandate: mandate
    }
    let(:mail) { MandateMailer.change_address_notification(email, mandate, product, address, old_address) }

    it "tracks document and mandate in ahoy email" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
    end
  end

  describe "#no_email_available_for_change_address_notification" do
    let(:address) { build :address, mandate: mandate }
    let(:old_address) { build :address, mandate: mandate }
    let(:product) {
      build :product, state: "under_management",
                      contract_ended_at: 1.day.ago,
                      renewal_period: nil,
                      mandate: mandate
    }

    let(:mail) do
      MandateMailer.no_email_available_for_change_address_notification(mandate, product, address, old_address)
    end

    it "tracks document and mandate in ahoy email" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
    end
  end

  describe "#changed_address_confirmation" do
    let(:address) { build :address, mandate: mandate }
    let(:mail) { MandateMailer.changed_address_confirmation(mandate, address) }
    let(:document_type) { DocumentType.changed_address_confirmation }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#portfolio_in_progress" do
    let!(:another_mandate) { create :mandate, user: user, state: :created }
    let(:inquiry) { create(:inquiry, mandate: mandate) }
    let(:mail) { MandateMailer.portfolio_in_progress(mandate, inquiry) }
    let(:document_type) { DocumentType.portfolio_in_progress }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"

    it "verifies the inquiry mandate is mandate" do
      mail = MandateMailer.portfolio_in_progress(another_mandate, inquiry)
      expect {
        mail.deliver_now
      }.to raise_error("portfolio mandate #{another_mandate.id} with inquiry #{inquiry.id}")
    end
  end

  describe "#portfolio_in_progress_4weeks" do
    let!(:another_mandate) { create :mandate, user: user, state: :created }
    let(:inquiry) { create(:inquiry, mandate: mandate) }
    let(:mail) { MandateMailer.portfolio_in_progress_4weeks(mandate, inquiry) }
    let(:document_type) { DocumentType.portfolio_in_progress_4weeks }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"

    it "verifies the inquiry mandate is mandate" do
      mail = MandateMailer.portfolio_in_progress_4weeks(another_mandate, inquiry)
      expect {
        mail.deliver_now
      }.to raise_error("portfolio 4 mandate #{another_mandate.id} with inquiry #{inquiry.id}")
    end
  end

  describe "#portfolio_in_progress 16 weeks" do
    let!(:another_mandate) { create :mandate, user: user, state: :created }
    let(:inquiry) { create(:inquiry, mandate: mandate) }
    let(:mail) { MandateMailer.portfolio_in_progress_16weeks(mandate, inquiry) }
    let(:document_type) { DocumentType.portfolio_in_progress_16weeks }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"

    it "verifies the inquiry mandate is mandate" do
      mail = MandateMailer.portfolio_in_progress_16weeks(another_mandate, inquiry)
      expect {
        mail.deliver_now
      }.to raise_error("portfolio 16 mandate #{another_mandate.id} with inquiry #{inquiry.id}")
    end
  end

  describe "#notification_available" do
    let(:mail) { MandateMailer.notification_available(advice) }
    let(:advice) { create :advice, mandate: mandate }
    let(:document_type) { DocumentType.notification_available }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#iban_for_invitation_payout" do
    let(:mail) { MandateMailer.iban_for_invitation_payout(mandate) }
    let(:document_type) { DocumentType.iban_for_invitation_payout }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#advice_reply_notification" do
    let(:mail) { MandateMailer.advice_reply_notification(mandate) }
    let(:document_type) { DocumentType.advice_reply_notification }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#voucher_greeting" do
    let(:mail) { MandateMailer.voucher_greeting(mandate) }
    let(:document_type) { DocumentType.voucher_greeting }

    describe "with ahoy email tracking" do
      it "includes the tracking pixel" do
        expect(mail.body.encoded).to match(/open\.gif/)
      end

      it "replaces links with tracking links" do
        expect(mail.body.encoded).to match(/click\?signature/)
      end

      include_examples "checks mail rendering"
      it_behaves_like "stores a message object upon delivery",
                      "MandateMailer#voucher_greeting",
                      "mandate_mailer",
                      "voucher_greeting"
      it_behaves_like "tracks document and mandate in ahoy email"
      it_behaves_like "does not send out an email if mandate belongs to the partner"
    end
  end
end
