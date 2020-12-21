# frozen_string_literal: true

RSpec.shared_examples "an owner" do |ident|
  describe ".send_greeting_mail" do
    let(:mandate) { create(:mandate) }
    let(:partner_mailer) { double(PartnerMailer, deliver_now: true) }

    before { allow(PartnerMailer).to receive(:partner_greeting).and_return(partner_mailer) }

    it "sends PartnerMailer" do
      described_class.send_greeting_mail(mandate)
      expect(partner_mailer).to have_received(:deliver_now)
    end
  end

  describe ".source_info" do
    it "return correct source info" do
      source_info = {anonymous_lead: true, adjust: {"network": ident.camelize}}
      expect(described_class.source_info).to eq(source_info)
    end
  end
end
