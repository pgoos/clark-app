# frozen_string_literal: true

require "rails_helper"
require "composites/payback/outbound/client"
require "composites/payback/outbound/mocks/fake_client"
require "composites/payback/factories/client"

RSpec.describe Payback::Factories::Client do
  let(:payback_number) { Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX) }
  let(:client) { described_class.build(payback_number) }

  describe ".build" do
    context "when env is not in production" do
      it "should return instance of fake client in test env" do
        expect(client).to be_kind_of(Payback::Outbound::Mocks::FakeClient)
      end
    end

    context "when env is in production" do
      it "should return instance of fake client in test env" do
        allow(Rails).to receive_message_chain(:env, :production?).and_return true
        expect(client).to be_kind_of(Payback::Outbound::Client)
      end
    end
  end

  describe ".configurations_available?" do
    context "when env is not in production" do
      it "should call configurations_available? on the fake client" do
        expect(Payback::Outbound::Mocks::FakeClient).to receive(:configurations_available?)

        described_class.configurations_available?
      end
    end

    context "when env is in production" do
      before do
        allow(Rails).to receive_message_chain(:env, :production?).and_return true
      end

      it "should call configurations_available? on the real client" do
        expect(Payback::Outbound::Client).to receive(:configurations_available?)

        described_class.configurations_available?
      end
    end
  end
end
