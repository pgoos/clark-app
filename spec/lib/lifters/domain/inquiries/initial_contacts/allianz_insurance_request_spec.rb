# frozen_string_literal: true

require "rails_helper"
require_relative "../inquiry_mail_resolver_shared_examples"

RSpec.describe Domain::Inquiries::InitialContacts::AllianzInsuranceRequests do
  let(:inquiry) { instance_double(Inquiry, categories: categories) }
  let(:categories) { [double("categories", vertical_ident: "GKV")] }
  let(:address) { "dunkelverarbeitung.krankenvertrag@allianz.de" }
  let(:mail) { double("mail") }

  before do
    allow(inquiry).to receive(:contact)
    allow(InquiryMailer).to receive(:insurance_request)
      .with(inquiry: inquiry, categories: categories, ident: described_class.ident, insurer_mandates_email: address)
      .and_return(mail)
    allow(mail).to receive(:deliver_now).with(no_args)
  end

  context "when enabled" do
    before do
      subject.send_insurance_requests(inquiry)
    end

    it { expect(InquiryMailer).to have_received(:insurance_request) }
  end

  context "when inquiry is updated" do
    it "should update the inquiry state" do
      expect(inquiry).to receive(:contact)
      subject.send_insurance_requests(inquiry)
    end
  end
end
