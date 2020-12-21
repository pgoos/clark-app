# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Tracking::MaintainMandateFlags do
  let(:mandate) { create :mandate }
  before do
    mandate.info["front_end_flags"] = {}
  end

  context "when enqueueing event" do
    before do
      Wisper.clear
      Tracking::Event.subscribe(described_class, async: true)
    end

    it "does not enqueue if it can't be processed" do
      perform_enqueued_jobs do
        expect(described_class).not_to receive(:after_create)
        create(:tracking_event, name: "general name")
      end
    end

    it "enqueues when the event is allowed" do
      perform_enqueued_jobs do
        expect(described_class).to receive(:after_create)
        create(:tracking_event, name: described_class::EVENT_FLAG_MAPPING.keys.first)
      end
    end
  end

  context ".can_process?" do
    it "only process events that are listed in the allowed events mapping hash" do
      event = build(:tracking_event, name: described_class::EVENT_FLAG_MAPPING.keys.first)
      expect(described_class.can_process?(event)).to be_truthy
    end

    it "does not process events that are not in the list of events mapping hash" do
      event = build(:tracking_event, name: "some_other_name")
      expect(described_class.can_process?(event)).to be_falsey
    end
  end

  context ".after_create" do
    it "calls the corresponding method in the event flag mapping hash if mandate is existent and can process the tracking event" do
      event_name = described_class::EVENT_FLAG_MAPPING.keys.first
      event = build(:tracking_event, name: event_name, mandate: mandate)
      described_class::EVENT_FLAG_MAPPING[event_name].each do |handler_method|
        expect(described_class).to receive(handler_method).with(mandate, event)
      end
      described_class.after_create(event)
    end

    it "does not call the method if mandate is not available and raise an exception" do
      event_name = described_class::EVENT_FLAG_MAPPING.keys.first
      event = build(:tracking_event, name: event_name)
      described_class::EVENT_FLAG_MAPPING[event_name].each do |handler_method|
        expect(described_class).not_to receive(handler_method).with(mandate, event)
      end
      expect { described_class.after_create(event) }.to raise_exception("no mandate found")
    end
  end

  context ".add_boolean_flag" do
    it "sets a flag with the event name on mandate to true" do
      event_name = described_class::EVENT_FLAG_MAPPING.keys.first
      event = build(:tracking_event, name: event_name, mandate: mandate)
      described_class.send(:add_boolean_flag, mandate, event)
      expect(mandate.info["front_end_flags"][event.name]).to be_truthy
    end
  end

  context ".add_timestamp" do
    it "sets a timestamp with the event name on mandate to current time" do
      event_name = described_class::EVENT_FLAG_MAPPING.keys.first
      event = build(:tracking_event, name: event_name, mandate: mandate)
      described_class.send(:add_timestamp, mandate, event)
      expect(mandate.info["front_end_flags"]["#{event.name}_timestamp"]).to be_present
    end
  end

  context ".add_number_of_occurrences" do
    it "sets a number of occurrences to 1 if this was the first time to handle this event" do
      event_name = described_class::EVENT_FLAG_MAPPING.keys.first
      event = build(:tracking_event, name: event_name, mandate: mandate)
      described_class.send(:add_number_of_occurrences, mandate, event)
      expect(mandate.info["front_end_flags"]["#{event.name}_occurrences"]).to eq(1)
    end

    it "increase number of occurrences by 1 if there was already number of occurrences" do
      event_name = described_class::EVENT_FLAG_MAPPING.keys.first
      event = build(:tracking_event, name: event_name, mandate: mandate)
      mandate.info["front_end_flags"]["#{event.name}_occurrences"] = 1
      described_class.send(:add_number_of_occurrences, mandate, event)
      expect(mandate.info["front_end_flags"]["#{event.name}_occurrences"]).to eq(2)
    end
  end
end
