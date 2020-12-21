# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Owners::Clark, :integration do
  describe ".send_greeting_mail" do
    let(:mandate) { create(:mandate) }
    let(:malburg_mailer) { double(MalburgMailer, deliver_now: true) }

    before { allow(MalburgMailer).to receive(:fb_malburg_greeting).and_return(malburg_mailer) }

    it "sends Facebook Malburg email" do
      described_class.send_greeting_mail(mandate)
      expect(malburg_mailer).to have_received(:deliver_now)
    end
  end

  describe ".source_info" do
    it "return correct source info" do
      source_info = {anonymous_lead: true, adjust: {"network": "fb-malburg"}}
      expect(described_class.source_info).to eq(source_info)
    end
  end
end
