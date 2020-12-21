# frozen_string_literal: true

require "rails_helper"
require "composites/home24/outbound/sqs/client"

RSpec.describe Home24::Outbound::Sqs::Client do
  let(:subject) { described_class.new }
  let(:sqs_client) { double("Aws::SQS::Client") }
  let(:queue_url) {
    Settings.event_queue.url_prefix + "_" + Home24::Outbound::Sqs::Client::QUEUE_NAME
  }

  before do
    allow(Home24::Outbound::Sqs::Logger).to receive(:error).and_return(true)
    allow(Home24::Outbound::Sqs::Logger).to receive(:info).and_return(true)
    allow(Aws::SQS::Client).to receive(:new) { sqs_client }
  end

  describe "#send_message" do
    include_context "home24 with order"

    let(:order_number) { home24_order_number }
    let(:message_body) { { mandate_id: 1, order_number: order_number }.to_json }

    before do
      allow(sqs_client).to receive(:send_message).and_return(true)
    end

    it "sends the message via sqs client" do
      expect(sqs_client).to receive(:send_message).with(
        queue_url: queue_url,
        message_body: message_body
      )
      subject.send_message(message_body)
    end

    context "when there is exception thrown" do
      before do
        allow(sqs_client).to receive(:send_message).and_raise(Aws::SQS::Errors::ServiceError)
      end

      it "returns false" do
        expect(subject.send_message(message_body)).to be_falsey
      end

      it "logs error" do
        expect(Home24::Outbound::Sqs::Logger).to receive(:error)

        subject.send_message(message_body)
      end
    end
  end

  describe "#receive_message" do
    let(:max_no_of_messages) { 10 }

    before do
      allow(sqs_client).to receive(:receive_message).and_return([])
    end

    it "gets the message via sqs client" do
      expect(sqs_client).to receive(:receive_message).with(
        queue_url: queue_url,
        max_number_of_messages: max_no_of_messages
      )

      subject.receive_message(max_no_of_messages)
    end
  end

  describe "#delete_message" do
    let(:receipt_handle) { "receipt handle" }

    before do
      allow(sqs_client).to receive(:delete_message).and_return(true)
    end

    it "deletes the message via sqs client" do
      expect(sqs_client).to receive(:delete_message).with(
        queue_url: queue_url,
        receipt_handle: receipt_handle
      )

      subject.delete_message(receipt_handle)
    end
  end
end
