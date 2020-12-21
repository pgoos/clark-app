# frozen_string_literal: true

require "rails_helper"

require Rails.root.join("app", "composites", "customer", "entities", "customer")

RSpec.describe Domain::Mandates::SelfServiceCustomerCreated do
  let(:mandate) { double(:mandate, id: 1, customer_state: state) }

  before { allow(Mandate).to receive(:find).with(mandate.id).and_return(mandate) }

  context "customer state is set to self_service" do
    let(:state) { Customer::Entities::Customer::SELF_SERVICE }

    it "creates interaction" do
      expect(
        OutboundChannels::Messenger::TransactionalMessenger
      ).to receive(:self_service_customer_created).with(mandate)

      described_class.call(mandate.id)
    end
  end

  context "customer state is set to mandate customer" do
    let(:state) { Customer::Entities::Customer::MANDATE_CUSTOMER }

    it "does not create an interaction" do
      expect(
        OutboundChannels::Messenger::TransactionalMessenger
      ).not_to receive(:self_service_customer_created).with(mandate)

      described_class.call(mandate.id)
    end
  end

  context "customer state is set to nil" do
    let(:state) { nil }

    it "does not create an interaction" do
      expect(
        OutboundChannels::Messenger::TransactionalMessenger
      ).not_to receive(:self_service_customer_created)

      described_class.call(mandate.id)
    end
  end
end
