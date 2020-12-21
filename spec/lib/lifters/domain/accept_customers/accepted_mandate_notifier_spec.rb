# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::AcceptCustomers::AcceptedMandateNotifier do
  let(:mandate) { create(:mandate, state: "created", user: create(:user)) }

  context "#send_greeting_mail" do
    it "does not send out the greeting email to a device lead" do
      mandate = build(:mandate, state: "in_creation", lead: build(:device_lead))

      expect(MandateMailer).not_to receive(:greeting)
      described_class.send_greeting_mail(mandate)
    end

    it "does not send out the greeting mail when it was sent before", :integration do
      mandate = create(:mandate, state: "in_creation", user: create(:user))
      mandate.documents << create(
        :document, document_type: DocumentType.greeting
      )

      expect(MandateMailer).not_to receive(:greeting)
      described_class.send_greeting_mail(mandate)
    end

    it "sends out the greeting mail if it was not sent before" do
      mandate = build(:mandate, state: "in_creation", user: build(:user))
      expect(Domain::Mails::MandateMails).to receive(:greeting_mail)
      described_class.send_greeting_mail(mandate)
    end
  end
end
