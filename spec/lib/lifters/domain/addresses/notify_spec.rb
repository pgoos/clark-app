# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Addresses::Notify, :integration do
  subject(:notify) { described_class.new insurer_email: ->(_) { insurer_email } }

  let(:insurer_email) { "sample@127.0.0.1" }

  let(:mandate)     { create :mandate, :accepted }
  let(:old_address) { object_double Address.new }
  let(:mail)        { double :mail, deliver_later: nil }
  let(:new_address) { object_double Address.new, notifiable?: true, insurers_notified!: true }

  it "does not set the address to insurers_notified == true, if there are no active products" do
    expect(new_address).not_to receive(:insurers_notified!)
    notify.(mandate, new_address, old_address)
  end

  context "with products" do
    let(:product) { create :shallow_product, :details_available, mandate: mandate }

    before do
      product
      mandate.reload
    end

    it "sends an email to the product insurer" do
      expect(MandateMailer).to receive(:change_address_notification) \
        .with(insurer_email, mandate, product, new_address, old_address) \
        .and_return(mail)
      expect(MandateMailer).to receive(:changed_address_confirmation) \
        .with(mandate, new_address).and_return(mail)
      expect(mail).to receive(:deliver_later).twice
      notify.(mandate, new_address, old_address)
    end

    it "marks address as notified" do
      allow(MandateMailer).to receive(:change_address_notification) \
        .with(insurer_email, mandate, product, new_address, old_address) \
        .and_return(mail)
      allow(MandateMailer).to receive(:changed_address_confirmation) \
        .with(mandate, new_address).and_return(mail)
      allow(mail).to receive(:deliver_later).twice

      expect(new_address).to receive(:insurers_notified!)
      notify.(mandate, new_address, old_address)
    end

    context "when new address is not notifiable" do
      let(:new_address) { object_double Address.new, notifiable?: false }

      it "does not notify insurers" do
        expect(new_address).not_to receive(:insurers_notified!)
        notify.(mandate, new_address, old_address)
      end
    end

    context "when new address is the same as old" do
      let(:old_address) { new_address }

      it "does not notify insurers" do
        expect(new_address).not_to receive(:insurers_notified!)
        notify.(mandate, new_address, old_address)
      end
    end
  end

  context "when product is not active" do
    let(:product) { create :shallow_product, :terminated, mandate: mandate }

    it "does not send an email to the product insurer" do
      expect(MandateMailer).not_to receive(:change_address_notification) \
          .with("INSURER_EMAIL", mandate, product, new_address, old_address)
      notify.(mandate, new_address, old_address)
    end
  end
end
