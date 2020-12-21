# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkJob do
  it { is_expected.to be_an(ActiveJob::Base) }
  it { expect(subject.job_id).to be_present }

  context "logging" do
    class DummyTestJob < ClarkJob
      queue_as :dummy_queue

      def inject_block(block)
        @block = block
      end

      def perform
        @block.call if @block.present?
      end

      def try_to_log(message, topic=nil)
        log_debug(message, topic)
        log_info(message, topic)
        log_warn(message, topic)
        log_error(message, topic)
        log_fatal(message, topic)
      end
    end

    def expect_to_log_all_severities(expected_message)
      expect(AsyncJobLog).to receive(:create!).with(
        job_id: subject.job_id,
        severity: Symbol,
        message: expected_message,
        topic: nil,
        queue_name: "dummy_queue",
        job_name: DummyTestJob.name
      ).exactly(5).times
    end

    let(:subject) { DummyTestJob.new }

    it "should log all severities" do
      AsyncJobLog.severities.keys.map(&:to_sym).each do |severity|
        expect(AsyncJobLog).to receive(:create!).with(
          job_id: subject.job_id,
          severity: severity,
          message: Hash,
          topic: nil,
          queue_name: subject.queue_name,
          job_name: DummyTestJob.name
        )
      end
      subject.try_to_log("key" => "value")
    end

    it "should log a simple text message" do
      expected_message = "simple text #{rand}"
      expect_to_log_all_severities("text" => expected_message)
      subject.try_to_log(expected_message)
    end

    it "should log something, if the message is nil" do
      expect_to_log_all_severities("text" => "nil")
      subject.try_to_log(nil)
    end

    it "should log something, if the message is empty" do
      expect_to_log_all_severities("text" => "empty string")
      subject.try_to_log("")
    end

    it "should log something, if the message is white space only" do
      expected_message = "\t\n\r\b"
      expect_to_log_all_severities("text" => expected_message)
      subject.try_to_log(expected_message)
    end

    it "should log an object" do
      object = Object.new
      expect_to_log_all_severities("type" => object.class.name, "inspection" => object.inspect)
      subject.try_to_log(object)
    end

    it "should log a hash" do
      hash = {"key_#{rand}" => "value_#{rand}"}
      expect_to_log_all_severities(hash)
      subject.try_to_log(hash)
    end

    it "should log an empty hash" do
      hash = {}
      expect_to_log_all_severities("hash" => "empty")
      subject.try_to_log(hash)
    end

    it "should log the topic" do
      topic = instance_double(Mandate)
      expect(AsyncJobLog).to receive(:create!).with(
        job_id: subject.job_id,
        severity: Symbol,
        message: Hash,
        topic: topic,
        queue_name: subject.queue_name,
        job_name: DummyTestJob.name
      ).exactly(5).times
      subject.try_to_log({"key" => "value"}, topic)
    end

    it "creates the database item", type: :integration do
      topic = create(:mandate)
      expected_message = {"key" => "value"}
      subject.try_to_log(expected_message, topic)
      expect(AsyncJobLog.count).to eq(5)
      logged = AsyncJobLog.where(severity: AsyncJobLog.severities.values)
      expect(logged.count).to eq(5)
      logged.each do |entry|
        expect(entry.job_id).to eq(subject.job_id)
        expect(entry.message).to eq(expected_message)
        expect(entry.topic).to eq(topic)
      end
    end

    context "exceptions" do
      let(:error_class) { [StandardError, ArgumentError, RuntimeError].sample }
      let(:error_message) { "test exception #{rand}" }
      let(:error) { error_class.new(error_message) }

      def perform_now
        subject.perform_now
      rescue => _
      end

      before do
        subject.inject_block(proc { raise error })
      end

      context "performed" do
        before do
          perform_now
        end

        it "logs an exception as error" do
          expect(AsyncJobLog.last.severity).to eq("fatal")
        end

        it "logs the exception class" do
          expect(AsyncJobLog.last.message["exception"]).to eq(error_class.name)
        end

        it "logs the exception message" do
          expect(AsyncJobLog.last.message["error"]).to eq(error_message)
        end

        it "logs the stack trace" do
          expect(AsyncJobLog.last.message["backtrace"]).to eq(error.backtrace.join("\n"))
        end
      end

      it "does not stop the exception from being raised" do
        expect {
          subject.perform_now
        }.to raise_error(error_class)
      end

      it "forwards the error to Sentry" do
        allow(subject).to receive(:inspect).and_return(subject.inspect)
        expect(Raven).to receive(:capture_exception).with(
          error,
          extra: {
            error_class: subject.class,
            error_message: "Job failed: #{error}",
            job_id: subject.job_id,
            queue_name: subject.queue_name,
            inspection: subject.inspect
          }
        ).at_least(:once)

        perform_now
      end
    end
  end
end
