# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::ApiPartners::Clients::AmazonSqs do
  let(:subject) { described_class.new(partner_ident) }
  let(:partner_ident) { "test_partner" }
  let(:sqs_client) { double("Aws::SQS::Client") }
  let(:queue_url) {
    Settings.event_queue.url_prefix +
    Settings.event_queue.topic +
    partner_ident +
    Settings.event_queue.url_suffix
  }
  let(:logger) { Logger.new("/dev/null") }

  before do
    allow(Platform::ApiPartners::QueueLogger).to receive(:new).and_return(logger)
    allow(Aws::SQS::Client).to receive(:new) { sqs_client }
  end

  describe "#send_message" do
    let(:message_body) { {event: {event: "updated", action: "update", mandate: {id: 2}}}.to_json }
    let(:message_group_id) { "123" }

    before do
      allow(sqs_client).to receive(:send_message).and_return(true)
    end

    context "without a message_group_id" do
      it "logs an error" do
        expect(logger).to receive(:error)
        subject.send_message(message_body, nil)
      end
    end

    context "with message_group_id" do
      it "sends the message via sqs" do
        expect(sqs_client).to receive(:send_message).with(
          queue_url: queue_url,
          message_body: message_body,
          message_group_id: message_group_id
        )
        subject.send_message(message_body, message_group_id)
      end
    end
  end

  describe "#receive_message" do
    it "receive messages from the queue" do
      expect(sqs_client).to receive(:receive_message).with(
        queue_url: queue_url,
        max_number_of_messages: 1
      )
      subject.receive_message(1)
    end
  end

  describe "#delete_message" do
    let(:receipt_handle) { "receipt handle" }

    it "deletes the successfully processed message" do
      expect(sqs_client).to receive(:delete_message).with(
        queue_url: queue_url,
        receipt_handle: receipt_handle
      )
      subject.delete_message(receipt_handle)
    end
  end
end
