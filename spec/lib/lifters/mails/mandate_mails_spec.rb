# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mails::MandateMails do
  describe "#greeting_mail" do
    context "when the mandate has not yet received a greeting" do
      let(:mandate) { build(:mandate, :with_user) }

      it "delivers the greeting" do
        expect(MandateMailer).to receive_message_chain(:greeting, :deliver_now)
        described_class.greeting_mail(mandate, mandate.email, mandate.documents)
      end

      context "when source is a partner with a custom greeting" do
        shared_examples "sends custom partner greeting" do
          it "delivers the custom greeting" do
            custom_greeting_mailer = ("greeting_" + mandate.partner).to_sym

            expect(MandateMailer)
              .to receive_message_chain(custom_greeting_mailer, :deliver_now)

            described_class.greeting_mail(mandate, mandate.email, mandate.documents)
          end
        end

        context "when mam" do
          let(:mandate) { build(:mandate, :mam) }

          include_examples "sends custom partner greeting"
        end

        context "when primoco" do
          let(:user) { build(:user, source_data: {"adjust": {"network": "primoco"}}) }
          let!(:mandate) { build(:mandate, user: user) }

          include_examples "sends custom partner greeting"
        end

        context "when 1822direkt" do
          let(:user) { build(:user, source_data: {"adjust": {"network": "1822direkt"}}) }
          let!(:mandate) { build(:mandate, user: user) }

          include_examples "sends custom partner greeting"
        end

        context "when payback" do
          let(:mandate) { build(:mandate, :payback) }

          include_examples "sends custom partner greeting"
        end
      end

      context "when customer is a voucher user" do
        let(:mandate) { build(:mandate, :with_user, voucher: build(:voucher)) }

        it "delivers the custom greeting" do
          expect(MandateMailer)
            .to receive_message_chain("voucher_greeting".to_sym, :deliver_now)

          described_class.greeting_mail(mandate, mandate.email, mandate.documents)
        end
      end
    end

    context "the mandate has already received a greeting" do
      let(:mandate) { create(:mandate, :with_user) }

      it "does not deliver another greeting" do
        mandate.documents << build(:document, document_type: DocumentType.greeting)

        expect(MandateMailer).not_to receive(:greeting)
        described_class.greeting_mail(mandate, mandate, mandate.documents)
      end
    end

    context "when no email address has been provided" do
      let(:mandate) { build(:mandate, :with_user) }

      it "does not deliver the greeting" do
        expect(MandateMailer).not_to receive(:greeting)
        described_class.greeting_mail(mandate, nil, mandate.documents)
      end
    end
  end

  describe "#send_partner_email?" do
    context "when not a partner" do
      let(:mandate) { build(:mandate) }

      it "returns false" do
        expect(described_class.send(:send_partner_email?, mandate)).to be_falsey
      end
    end
  end
end
