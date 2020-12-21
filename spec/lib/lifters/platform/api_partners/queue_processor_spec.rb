# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::ApiPartners::QueueProcessor do
  let!(:event_dispatcher) { Platform::ApiPartners::EventDispatcher.new(Logger.new(nil)) }
  let(:client) { Platform::ApiPartners::Clients::MockClient }
  let(:api_partner_name) { "n26" }
  let(:logger) { Logger.new("/dev/null") }
  let(:subject) { described_class.new(client, logger, event_dispatcher, api_partner_name) }
  let(:message_entity) { create(:mandate) }
  let(:message_object) { ClarkAPI::Partners::Entities::Mandate.represent(message_entity, root: false) }
  let(:queue_message) {
    body = {
      event: {
        :event => "created",
        :action => "create",
        message_entity.class.name.downcase => message_object
      }
    }
    OpenStruct.new(message_id: "12345", body: body.to_json)
  }

  before do
    allow_any_instance_of(Logger).to receive(:error).and_return(nil)
    allow_any_instance_of(Logger).to receive(:info).and_return(nil)
    allow(event_dispatcher).to receive(:access_token).and_return(nil)
  end

  context "#initialize" do
    it("fetches the access token for n26 on initialize") do
      expect(event_dispatcher).to receive(:access_token)
      subject
    end
  end

  context "#stream_messages" do
    let(:sqs_object) { OpenStruct.new(messages: [queue_message]) }
    let(:sqs_empty_object) { OpenStruct.new(messages: []) }

    before do
      allow(client).to receive(:receive_message).with(1).and_return(sqs_object, sqs_empty_object)
    end

    it "should receive messages from Sqs and process them" do
      expect(subject).to receive(:process_message).with(queue_message)
      subject.stream_messages
    end
  end

  context "#process_message" do
    before do
      allow(event_dispatcher).to receive(:dispatch_event).and_return(code: 200)
      allow(client).to receive(:delete_message).and_return(nil)
    end

    it "raises an error if message has an unsupported entity" do
      unprocessable_object = create(:category)
      unprocessable_body = {
        headers: {persistent: true},
        event: {
          :event => "created",
          :action => "create",
          unprocessable_object.class.name.downcase => unprocessable_object.to_json
        }
      }

      unprocessable_message = OpenStruct.new(message_id: "1234", body: unprocessable_body.to_json)
      expect { subject.send(:process_message, unprocessable_message) }
        .to raise_error("Wrong entity name `#{unprocessable_object.class.name.downcase}` or message body")
    end

    it "process the message and pass it to the event dispatcher" do
      msg_event = JSON.parse(queue_message.body)["event"]
      expect(event_dispatcher).to receive(:dispatch_event).with(anything, msg_event.to_json, nil)
      subject.send(:process_message, queue_message)
    end
  end

  context "#check_entity_type" do
    it "raises and error if passed entity type is unsupported" do
      unsupported = Category.class_name.downcase
      expect { subject.send(:check_entity_type, unsupported) }
        .to raise_error("Wrong entity name `#{unsupported}` or message body")
    end

    it "doesn't raise an error if passed a supported entity type" do
      supported = Mandate.class_name.downcase
      expect { subject.send(:check_entity_type, supported) }
        .not_to raise_error
    end
  end

  context "#handle_dispatch_response" do
    context "successful response" do
      before do
        allow(client).to receive(:delete_message).and_return(nil)
      end

      let(:response) { {code: 200} }

      it "calls the client acknowledge method" do
        expect(client).to receive(:delete_message)
        subject.send(:handle_dispatch_response, response, queue_message, "12345678", "mandate", message_entity.id)
      end
    end

    context "unsuccessful response" do
      let(:response) { {code: 400} }

      it "raises an error with the entity id" do
        expect {
          subject.send(:handle_dispatch_response, response, queue_message, "12345678", "mandate", message_entity.id)
        }
          .to raise_error(StandardError, /Entity id: `#{message_entity.id}`/)
      end

      it "reports the error to special sentry instance for partners" do
        expect(Platform::RavenPartners.instance.sentry_logger).to receive(:capture_message)
        begin
          subject.send(:handle_dispatch_response, response, queue_message, "12345678", "mandate", message_entity.id)
        rescue StandardError
          # swallow the expected exception
        end
      end
    end
  end
end
