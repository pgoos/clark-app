# frozen_string_literal: true

require "rails_helper"
require "composites/payback/outbound/mocks/fake_client"
require "composites/payback/outbound/mocks/fake_response"

RSpec.describe Payback::Outbound::Mocks::FakeResponse do
  let(:response) { described_class.new(payback_number, {}) }

  let(:operation_to_execute) { :process_purchase_event }
  let(:payback_number) { Luhn.generate(16, prefix: Payback::Entities::Customer::PAYBACK_NUMBER_PREFIX) }

  before do
    allow(response).to receive(:check_for_authentication).and_return(true)
  end

  describe "#generate" do
    it "should rails error when operation is not allowed" do
      expect { response.generate(:test_operation, {}) }.to raise_exception(ArgumentError)
    end

    context "when http response is successfully" do
      let(:savon_response) { response.generate(operation_to_execute, {}) }

      it "should be savon response instance" do
        expect(savon_response).to be_kind_of(Savon::Response)
      end

      it "should return a successfully savon response" do
        expect(savon_response).to be_successful
      end

      it "should return a hash on body containing event response key" do
        expect(savon_response.body["#{operation_to_execute}_response".to_sym]).to be_kind_of Hash
      end
    end

    context "when http response is not successfully" do
      let(:savon_response) { response.generate(operation_to_execute, {}) }
      let(:error_text_body) {
        error_code = Payback::Outbound::Mocks::FakeResponse::ERROR_CODE
        error_message = Payback::Outbound::Mocks::FakeResponse::ERROR_MESSAGE
        Payback::Outbound::Mocks::FakeResponse.get_error_text_body(operation_to_execute, error_code, error_message)
      }

      before do
        allow(response).to receive(:http_code).and_return(500)
        allow(response).to receive(:get_text_body).and_return(error_text_body)
      end

      it "should return a successfully savon response" do
        expect(savon_response).not_to be_successful
      end

      it "should return a hash on body containing event response key" do
        expect(savon_response.body["#{operation_to_execute}_response".to_sym]).to be_kind_of Hash
      end

      it "should contain fault_message info" do
        hash_response = savon_response.body["#{operation_to_execute}_response".to_sym]
        expect(hash_response[:fault_message]).to be_kind_of Hash
      end
    end
  end
end
