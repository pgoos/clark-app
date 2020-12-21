# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Constituents::UpgradeJourney::Interactors::RequestCorrections do
  subject(:request) { described_class.new(emit_event: emit_event, customer_repo: customer_repo) }

  let(:customer_repo) { double :repo, find: customer, update!: true }
  let(:emit_event) { double :emitter, call: nil }

  let(:customer) do
    double(
      :customer,
      upgrade_journey_state: "finished",
      mandate_state: "created",
      customer_state: "mandate_customer"
    )
  end

  it "updates customer states" do
    expect(customer_repo).to receive(:find).with(999).and_return(customer)
    expect(customer_repo).to \
      receive(:update!).with(
        999,
        {
          upgrade_journey_state: "profile",
          mandate_state: "in_creation",
          customer_state: "self_service"
        },
        audit_business_event: :request_corrections
      )
    result = request.(999)
    expect(result).to be_successful
  end

  it "exposes customer" do
    result = request.(999)
    expect(result.customer).to eq customer
  end

  it "emits an event" do
    expect(emit_event).to receive(:call).with(:upgrade_corrections_requested, 999)
    request.(999)
  end

  context "with invalid states" do
    context "with invalid mandate state" do
      let(:customer) do
        double(
          :customer,
          upgrade_journey_state: "finished",
          mandate_state: "in_creation",
          customer_state: "mandate_customer"
        )
      end

      it "returns an error" do
        result = request.(999)
        expect(result).to be_failure
        expect(result.errors).to include "request_corrections: invalid transition from in_creation"
      end
    end

    context "with invalid customer state" do
      let(:customer) do
        double(
          :customer,
          upgrade_journey_state: "finished",
          mandate_state: "created",
          customer_state: "self_service"
        )
      end

      it "returns an error" do
        result = request.(999)
        expect(result).to be_failure
        expect(result.errors).to include "reset_mandate: invalid transition from self_service"
      end
    end
  end
end
