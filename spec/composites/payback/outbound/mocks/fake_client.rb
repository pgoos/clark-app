# frozen_string_literal: true

require "rails_helper"
require "composites/payback/outbound/mocks/fake_client"
require "composites/payback/outbound/mocks/fake_response"

RSpec.describe Payback::Outbound::Mocks::FakeClient do
  let(:client) { described_class.new(payback_number) }

  let(:payback_number) { Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX) }
  let(:fake_response) { Payback::Outbound::Mocks::FakeResponse.new(payback_number, {}) }

  describe "#call" do
    before do
      allow(Payback::Outbound::Mocks::FakeResponse).to receive(:new).and_return(fake_response)
    end

    it "should call the method for adding the data" do
      expect(client).to receive(:add_auth_and_partner_data)
      client.call(:process_purchase_event, message: {})
    end

    it "should initialize a fake response instance" do
      expect(Payback::Outbound::Mocks::FakeResponse).to receive(:new)
      client.call(:process_purchase_event, message: {})
    end

    context "when there are values to be replaced in body" do
      let(:values_to_replace) { {"$TEST$" => "test"} }
      let(:operation_to_execute) { :process_purchase_event }

      before do
        allow(client).to receive(:"#{operation_to_execute}_values")\
          .and_return(values_to_replace)
      end

      it "should execute the generate method including the values to be replaced" do
        expect(fake_response).to receive(:generate).with(operation_to_execute, values_to_replace)
        client.call(operation_to_execute, message: {})
      end
    end

    it "should return instance of savon response" do
      response = client.call(:process_purchase_event, message: {})
      expect(response).to be_kind_of(Savon::Response)
    end
  end
end
