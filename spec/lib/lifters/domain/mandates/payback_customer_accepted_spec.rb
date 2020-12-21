# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::PaybackCustomerAccepted do
  let(:mandate) { double(:mandate, id: 1) }

  before do
    allow(Payback).to receive(:handle_accepted_mandate).and_return(double("Utils::Interactor::Result"))
  end

  it "calls the method on payback composite namespace to handle it" do
    expect(Payback).to receive(:handle_accepted_mandate).with(mandate.id)

    described_class.call(mandate)
  end
end
