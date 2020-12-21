# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::InitialContacts::GenericInsuranceRequest do
  let(:inquiry) do
    instance_double(Inquiry, active_categories: categories, insurer_mandates_email: "FOO@BAR.DE")
  end
  let(:categories) { double("categories") }
  let(:mail) { double("mail") }

  before do
    allow(inquiry).to receive(:contact)
    allow(InquiryMailer).to receive(:insurance_request)
      .with(
        inquiry: inquiry,
        categories: categories,
        ident: described_class.ident,
        insurer_mandates_email: "FOO@BAR.DE"
      ).and_return(mail)
    allow(mail).to receive(:deliver_now).with(no_args)
  end

  context "when enabled" do
    before do
      subject.send_insurance_requests(inquiry)
    end

    it { expect(InquiryMailer).to have_received(:insurance_request) }
    it { expect(mail).to have_received(:deliver_now) }

    context "when insurer mandates email is blank" do
      let(:inquiry) { instance_double(Inquiry, categories: categories, insurer_mandates_email: "") }

      it { expect(InquiryMailer).not_to have_received(:insurance_request) }
      it { expect(mail).not_to have_received(:deliver_now) }
    end
  end

  context "when inquiry is updated" do
    it "should update the inquiry state" do
      expect(inquiry).to receive(:contact)
      subject.send_insurance_requests(inquiry)
    end
  end
end
