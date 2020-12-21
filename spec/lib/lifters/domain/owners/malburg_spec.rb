# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Owners::Malburg, :integration do
  describe ".send_greeting_mail" do
    let(:user) { create(:lead, :with_mandate) }
    let(:malburg_mailer) { double(MalburgMailer, deliver_now: true) }

    before { allow(MalburgMailer).to receive(:clark_greeting).and_return(malburg_mailer) }

    it "sends MalburgMailer" do
      described_class.send_greeting_mail(user.mandate)
      expect(malburg_mailer).to have_received(:deliver_now)
    end
  end

  describe ".source_info" do
    it "return correct source info" do
      source_info = {anonymous_lead: true, adjust: {"network": "Malburg", "campaign": "Call"}}
      expect(described_class.source_info).to eq(source_info)
    end
  end
end
