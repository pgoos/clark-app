# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataProtectionMailer, :integration, type: :mailer do
  let!(:admin_email) { "admin@test.de" }
  let!(:admin) { create :admin, email: admin_email }
  let!(:mandate) { create :mandate }

  describe "#export_notification" do
    let(:mail) { described_class.export_notification(admin, mandate) }

    it "renders headers" do
      expect(mail.from).to eq([Settings.emails.service])
      expect(mail.to).to eq([admin_email])
      expect(mail.subject).to eq("Kundendaten erfolgreich exportiert")
    end

    it "renders body" do
      expect(mail.body.encoded).to include("ID:#{mandate.id}")
    end
  end

  describe "#deletion_notification" do
    let(:mail) { described_class.deletion_notification(admin, mandate.id) }

    it "renders headers" do
      expect(mail.from).to eq([Settings.emails.service])
      expect(mail.to).to eq([admin_email])
      expect(mail.subject).to eq("Kunde erfolgreich gelöscht")
    end

    it "renders body" do
      expect(mail.body.encoded).to include("ID:#{mandate.id}")
    end
  end
end
