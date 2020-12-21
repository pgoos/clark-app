# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::Async::ActiveJobBroadcaster do
  before do
    described_class.register # done in config/initializers/event_observable.rb
  end

  context "configuration" do
    let(:configuration) {Wisper.configuration}

    it "configures active_job as a broadcaster" do
      expect(configuration.broadcasters).to include :active_job
    end

    it "configures as default async broadcaster" do
      broadcaster = configuration.broadcasters[:async]
      expect(broadcaster.class.name).to eq(Platform::Async::ActiveJobBroadcaster.name)
    end
  end

  context "pub / subscribe async" do
    let(:publisher) do
      Class.new do
        include Wisper::Publisher

        def run
          broadcast(:it_happened, "hello, world")
        end
      end.new
    end

    let(:subscriber) do
      Class.new do
        def self.it_happened
          # noop
        end

        def self.name
          "Namespace::SubscriberClassName"
        end
      end
    end

    let(:adapter) { ActiveJob::Base.queue_adapter }
    let(:wrapper_class) { Platform::Async::ActiveJobBroadcaster::Wrapper }

    it "puts job on ActiveJob queue" do
      publisher.subscribe(subscriber, async: true)

      publisher.run

      expect(adapter.enqueued_jobs.size).to eq 1
    end

    it "should create a clark job" do
      job_wrapper_instance = wrapper_class.new
      expect(job_wrapper_instance).to be_a(ClarkJob)
    end

    it "should queue as <SUBJECT_NAME_IN_SNAKECASE>_events" do
      publisher.subscribe(subscriber, async: true)

      expected_queue_name = (subscriber.name.tr(":", "").snakecase + "_events").to_sym
      expect(expected_queue_name).not_to eq(:class_events)
      expect(wrapper_class).to receive(:set).with(queue: expected_queue_name).and_call_original

      publisher.run
    end

    context "subscriber implements drop?" do
      it "should filter publishers if subscribers drop them" do
        def subscriber.drop?(_)
          true
        end

        publisher.subscribe(subscriber, async: true)
        expect(wrapper_class).not_to receive(:set)

        publisher.run
      end

      it "should pass the publisher if subscribers filter" do
        subscriber.instance_variable_set(:@expected_publisher, publisher)
        def subscriber.drop?(actual_publisher)
          raise "publisher not passed" unless actual_publisher == @expected_publisher
          true
        end

        publisher.subscribe(subscriber, async: true)

        publisher.run
      end
    end
  end
end
