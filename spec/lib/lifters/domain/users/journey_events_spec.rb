# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Users::JourneyEvents do
  let(:rating_status_class) { Domain::Ratings::RatingStatus }
  let(:fake_payload_validator) do
    Class.new do
      def initialize
        @called = false
      end

      def validate(payload:)
        @called = payload.is_a?(Hash)
      end

      def called?
        @called
      end
    end
  end

  context "when appended in integration", :integration, :business_events do
    let(:positive_integer) { rand(1..100) }

    it "should append an event" do
      BusinessEvent.audit_person = create(:admin, role: create(:role))

      mandate = create(:mandate)

      # define some event names
      event_name1 = "event_name1"
      event_name2 = "event_name2"
      event_names = [event_name1, event_name2]

      journey = described_class.new(mandate: mandate, payload_validators: {generic: fake_payload_validator.new})
      select_events = -> { journey.events.select { |event| event_names.include?(event.action) } }

      # initial state
      expect(select_events.()).to be_empty

      # append one event
      payload1 = {"key1_#{positive_integer}" => "value1_#{positive_integer}"}
      journey.append(event_name: event_name1, payload: payload1)
      mandate.reload

      event = select_events.().first
      expect(event.action).to eq(event_name1)
      expect(event.metadata["payload"]).to eq(payload1)

      # append a second event
      payload2 = {"key2_#{positive_integer}" => "value2_#{positive_integer}"}
      journey.append(event_name: event_name2, payload: payload2)
      mandate.reload

      expect(select_events.().count).to eq(2)

      event1 = select_events.().first
      expect(event1.action).to eq(event_name1)
      expect(event1.metadata["payload"]).to eq(payload1)

      event2 = select_events.().last
      expect(event2.action).to eq(event_name2)
      expect(event2.metadata["payload"]).to eq(payload2)

      expect(event1.created_at < event2.created_at).to be_truthy
    end
  end

  context "when loading the rating status" do
    let(:event_name) { rating_status_class.event_names.sample }
    let(:business_events) { [build(:business_event, action: event_name, created_at: 1.day.ago)] }
    let(:mandate) { instance_double(Mandate, business_events: business_events) }
    let(:rating_status) { instance_double(rating_status_class) }

    it "should create the rating status" do
      allow(Domain::Ratings::RatingStatus).to \
        receive(:new).with(events: business_events, mandate: mandate).and_return(rating_status)
      expect(described_class.new(mandate: mandate).rating_status).to eq(rating_status)
    end
  end

  context "when with payload" do
    subject { described_class.new(mandate: mandate, payload_validators: additional_validators) }

    let(:mandate) { instance_double(Mandate) }
    let(:generic_validator) { Domain::Users::JourneyEvents::GenericPayloadValidator }
    let(:event_name) { "some_event" }
    let(:additional_validators) { {} }

    before do
      allow(BusinessEvent).to receive(:audit).with(any_args)
    end

    it "should call the generic validator" do
      expect_any_instance_of(generic_validator).to receive(:validate).with(payload: {})
      subject.append(event_name: event_name, payload: {})
    end

    it "should create the business event" do
      expect(BusinessEvent).to receive(:audit).with(mandate, event_name, payload: {})
      subject.append(event_name: event_name, payload: {})
    end

    it "should reraise, if the generic payload validation raises to be invalid" do
      error = Domain::Users::JourneyEvents::EventPayloadError
      expect { subject.append(event_name: event_name, payload: nil) }.to raise_error(error)
    end

    it "should not create the business event, if the payload causes a validation error" do
      expect(BusinessEvent).not_to receive(:audit).with(any_args)
      begin
        subject.append(event_name: event_name, payload: nil)
      rescue Domain::Users::JourneyEvents::EventPayloadError => _
      end
    end

    it "should use the specific payload validators" do
      validator = double("payload_validator")
      payload = double("payload")
      additional_validators[event_name.to_sym] = validator

      expect(validator).to receive(:validate).with(payload: payload)

      subject.append(event_name: event_name, payload: payload)
    end

    {
      "rating_modal_triggered" => Domain::Users::JourneyEvents::RatingModalTriggeredValidator,
      "rating_modal_rated" => Domain::Users::JourneyEvents::RatingModalRatedValidator
    }.each do |event_name, validator_class|
      it "validates the payload for the #{event_name} event" do
        payload = double("payload")
        expect_any_instance_of(validator_class).to receive(:validate).with(payload: payload)
        subject.append(event_name: event_name, payload: payload)
      end
    end
  end
end
