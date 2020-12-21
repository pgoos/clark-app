# frozen_string_literal: true

require "rails_helper"

RSpec.describe Extensions::Clark::Domain::Inquiries::InitialContacts do
  describe ".sender_factory" do
    let(:base) { Domain::Inquiries::InitialContacts.new }
    let(:generic) { instance_double(base.class::GenericInsuranceRequest) }
    let(:allianz) { instance_double(base.class::AllianzInsuranceRequests) }
    let(:allianz_ident) { base.class::AllianzInsuranceRequests.ident }

    let(:drop_sending) { n_instance_double(base.class::DropInsuranceRequest, "drop_sending_double") }

    let(:axa_idents) { Domain::StockTransfer::Axa.company_idents }

    before do
      allow(base.class::GenericInsuranceRequest).to receive(:new).and_return(generic)
      allow(base.class::AllianzInsuranceRequests).to receive(:new).and_return(allianz)
      allow(base.class::DropInsuranceRequest).to receive(:instance).and_return(drop_sending)
    end

    it do
      expected_injection = {
        "generic" => generic,
        allianz_ident => allianz
      }
      axa_idents.each do |ident|
        expected_injection[ident] = drop_sending
      end
      expect(described_class.sender_factory("generic")).to eq(expected_injection)
    end
  end
end
