# frozen_string_literal: true

require "rails_helper"
require "composites/home24/outbound/sqs/fake_client"

RSpec.describe Home24::Outbound::Sqs::FakeClient do
  include_context "home24 with order"

  let(:subject) { described_class.new }
  let(:order_number) { home24_order_number }

  describe "#send_message" do
    let(:message_body) { { mandate_id: 1, order_number: order_number }.to_json }

    it "returns true" do
      expect(subject.send_message(message_body)).to be_truthy
    end
  end

  describe "#receive_message" do
    let(:max_no_of_messages) { 10 }

    it "returns empty array" do
      expect(subject.receive_message(max_no_of_messages).messages).to be_empty
    end
  end

  describe "#delete_message" do
    let(:receipt_handle) { "receipt handle" }

    it "returns true" do
      expect(subject.delete_message(receipt_handle)).to be_truthy
    end
  end
end
