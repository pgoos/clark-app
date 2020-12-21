# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mails::Invite do
  subject { described_class.new(user.mandate, admin) }

  let(:admin) { create(:admin) }
  let(:user) { create(:lead, :with_mandate) }

  context "with proper attributes" do
    let(:malburg_mailer) { double(MalburgMailer, deliver_now: true) }

    before {
      allow(MalburgMailer).to receive(:clark_greeting).and_return(malburg_mailer)
      user.source_data = {adjust: {network: "Malburg"}}
    }

    it "sends MalburgMailer" do
      subject.call
      expect(malburg_mailer).to have_received(:deliver_now)
    end

    it "creates an Interaction" do
      expect { subject.call }.to change(Interaction, :count).by(1)
    end
  end

  context "with errors" do
    before {
      allow(MalburgMailer).to receive(:clark_greeting).and_raise(ActiveRecord::RecordInvalid)
      user.source_data = {adjust: {network: "Malburg"}}
    }

    it "sends the error to Sentry and raises custom error" do
      expect(Raven).to receive(:capture_exception)
      expect { subject.call }.to raise_error(Domain::Mails::InviteError)
    end
  end

  context "with organic customer and network fb-malburg" do
    let(:clark_mandate) { create(:mandate) }
    let(:malburg_mailer) { double(MalburgMailer, deliver_now: true) }

    before {
      allow(MalburgMailer).to receive(:fb_malburg_greeting).and_return(malburg_mailer)
      user.source_data = {adjust: {network: "fb-malburg"}}
    }

    it "sends Facebook Malburg email" do
      subject.call
      expect(malburg_mailer).to have_received(:deliver_now)
    end
  end

  context "when the owner is communikom" do
    let!(:partner) { create(:partner, :active, ident: Domain::Owners::COMMUNIKOM_IDENT) }
    let(:partner_mailer) { double(PartnerMailer, deliver_now: true) }

    before {
      allow(PartnerMailer).to receive(:partner_greeting).and_return(partner_mailer)
      user.mandate.owner_ident = Domain::Owners::COMMUNIKOM_IDENT
      user.mandate.save!
    }

    it "sends an partner greeting email" do
      subject.call
      expect(partner_mailer).to have_received(:deliver_now)
    end
  end

  context "when the owner is zvo" do
    let!(:partner) { create(:partner, :active, ident: Domain::Owners::ZVO_IDENT) }
    let(:partner_mailer) { double(PartnerMailer, deliver_now: true) }

    before {
      allow(PartnerMailer).to receive(:partner_greeting).and_return(partner_mailer)
      user.mandate.owner_ident = Domain::Owners::ZVO_IDENT
      user.mandate.save!
    }

    it "sends an partner greeting email" do
      subject.call
      expect(partner_mailer).to have_received(:deliver_now)
    end
  end

  context "if mailer fails to send" do
    let(:clark_mandate) { create(:mandate) }
    let(:malburg_mailer) { double(MalburgMailer, deliver_now: nil) }

    before {
      allow(MalburgMailer).to receive(:fb_malburg_greeting).and_return(malburg_mailer)
      user.source_data = {adjust: {network: "fb-malburg"}}
    }

    it "does not create an interaction" do
      expect { subject.call }.not_to change(Interaction, :count)
    end
  end
end
