# frozen_string_literal: true

require "rails_helper"
require_relative "inquiry_mail_delegator_shared_examples"

RSpec.describe Domain::Inquiries::InitialContacts do
  subject do
    described_class.new(
      "generic"     => generic_sender,
      allianz_ident => allianz_sender
    )
  end

  let(:generic_sender) { instance_double(described_class::GenericInsuranceRequest) }
  let(:allianz_sender) { instance_double(described_class::AllianzInsuranceRequests) }

  let(:arbitrary_inquiry1) { instance_double(Inquiry, company_ident: "arbitrary1") }
  let(:arbitrary_inquiry2) { instance_double(Inquiry, company_ident: "arbitrary2") }

  let(:allianz_ident) { described_class::AllianzInsuranceRequests.ident }

  before do
    allow(generic_sender).to receive(:send_insurance_requests)
    allow(allianz_sender).to receive(:send_insurance_requests)
    allow(Features).to receive(:active?).and_call_original
    allow(Features).to receive(:active?).with(Features::INQUIRY_EMAILS).and_return(true)
  end

  it_behaves_like "an inquiry mail delegator", "initial_contacts"

  context "generic" do
    it "should pass an arbitrary inquiry to a generic sender" do
      expect(generic_sender).to receive(:send_insurance_requests).with(arbitrary_inquiry1)
      subject.send_insurance_requests([arbitrary_inquiry1])
    end

    it "should pass multiple arbitrary inquiries to a generic sender" do
      expect(generic_sender).to receive(:send_insurance_requests).once.with(arbitrary_inquiry1)
      expect(generic_sender).to receive(:send_insurance_requests).once.with(arbitrary_inquiry2)
      subject.send_insurance_requests([arbitrary_inquiry1, arbitrary_inquiry2])
    end
  end

  context "Allianz (allia8c23e2)" do
    let(:allianz_inquiry) { instance_double(Inquiry, company_ident: allianz_ident, contact: true) }

    it "should pass the sendable inquiries of Allianz to the AllianzSender" do
      expect(allianz_sender).to receive(:send_insurance_requests).once.with(allianz_inquiry)
      subject.send_insurance_requests([allianz_inquiry])
    end
  end

  describe "#extension" do
    it "return appropriate extension class" do
      expect(subject.extension).to be(Extensions::Clark::Domain::Inquiries::InitialContacts)

      allow(Settings.extensions.domain.inquiries).to receive(:initial_contacts).and_return("")
      expect(subject.extension).to be_nil
    end
  end
end
