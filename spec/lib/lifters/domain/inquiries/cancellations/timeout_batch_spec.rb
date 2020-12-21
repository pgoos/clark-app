# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::Cancellations::TimeoutBatch do
  subject { described_class.new(config) }

  let(:config) do
    {
      repository: repository,
      timeout: fixed_timeout,
      batch_size: fixed_batch_size,
      logger: logger
    }
  end
  let(:fixed_timeout) { 1.day.ago }
  let(:fixed_batch_size) { 10 }
  let(:repository) { double("repository") }
  let(:repository_params) { {time: fixed_timeout, limit: fixed_batch_size} }
  let(:repo_return_sequence) do
    # Make sure to pass in an empty array as last return of the sequence to avoid an endless loop in the test.
    lambda do |*sequence|
      allow(repository).to receive(:older_than).with(repository_params).and_return(*sequence)
    end
  end
  let(:logger) { double("logger") }

  let(:finalization_class) { Domain::Inquiries::Finalization }

  let(:positive_int) { rand(1..100) }

  let(:inquiry1) { instance_double(Inquiry, id: 1) }
  let(:category_ident1) { "category_#{inquiry_category1_id}" }
  let(:inquiry_category1_id) { positive_int }
  let(:inquiry_category1) do
    instance_double(
      InquiryCategory,
      id: inquiry_category1_id,
      inquiry: inquiry1,
      category_ident: category_ident1,
      product?: false
    )
  end
  let(:finalizer1) { instance_double(finalization_class) }

  let(:inquiry2) { instance_double(Inquiry, id: 2) }
  let(:category_ident2) { "category_#{inquiry_category2_id}" }
  let(:inquiry_category2_id) { positive_int + 1 }
  let(:inquiry_category2) do
    instance_double(
      InquiryCategory,
      id: inquiry_category2_id,
      inquiry: inquiry2,
      category_ident: category_ident2,
      product?: false
    )
  end
  let(:finalizer2) { instance_double(finalization_class) }

  let(:category_ident3) { "category_#{inquiry_category3_id}" }
  let(:inquiry_category3_id) { positive_int + 2 }
  let(:inquiry_category3) do
    instance_double(
      InquiryCategory,
      id: inquiry_category3_id,
      inquiry: inquiry1,
      category_ident: category_ident3,
      product?: false
    )
  end

  before do
    allow(logger).to receive(:info).with(String)
    dummy = instance_double(finalization_class)
    allow(dummy).to receive(:perform_available_cancellations!)
    allow(finalization_class).to receive(:new).with(any_args).and_return(dummy)
  end

  context "when no according product can be found" do
    it "should send a single inquiry category to cancellation" do
      cancellation_configs = {inquiry_category1_id => :timed_out}
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs).and_return(finalizer1)
      repo_return_sequence.([inquiry_category1], [])

      expect(finalizer1).to receive(:perform_available_cancellations!)

      subject.execute
    end

    it "should send multiple inquiry categories to cancellation" do
      cancellation_configs1 = {inquiry_category1_id => :timed_out}
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs1).and_return(finalizer1)
      allow(finalizer1).to receive(:perform_available_cancellations!)

      cancellation_configs2 = {inquiry_category2_id => :timed_out}
      allow(finalization_class).to receive(:new).with(inquiry2, cancellation_configs2).and_return(finalizer2)

      repo_return_sequence.([inquiry_category1, inquiry_category2], [])

      expect(finalizer2).to receive(:perform_available_cancellations!)

      subject.execute
    end

    it "should group the cancellation of multiple inquiry categories, if they belong to one inquiry" do
      cancellation_configs = {
        inquiry_category1_id => :timed_out,
        inquiry_category3_id => :timed_out
      }
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs).and_return(finalizer1)
      repo_return_sequence.([inquiry_category1, inquiry_category3], [])

      expect(finalizer1).to receive(:perform_available_cancellations!)

      subject.execute
    end

    it "should continue the batch, if a single cancellation fails" do
      allow(logger).to receive(:error).with(any_args)

      cancellation_configs1 = {inquiry_category1_id => :timed_out}
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs1).and_return(finalizer1)
      allow(finalizer1).to receive(:perform_available_cancellations!).and_raise("sample error")

      cancellation_configs2 = {inquiry_category2_id => :timed_out}
      allow(finalization_class).to receive(:new).with(inquiry2, cancellation_configs2).and_return(finalizer2)

      repo_return_sequence.([inquiry_category1, inquiry_category2], [])

      expect(finalizer2).to receive(:perform_available_cancellations!)

      subject.execute
    end
  end

  context "when a product is found" do
    it "should change the cause to 'complete'" do
      allow(inquiry_category1).to receive(:product?).and_return(true)
      cancellation_configs = {inquiry_category1_id => :complete}
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs).and_return(finalizer1)
      repo_return_sequence.([inquiry_category1], [])

      expect(finalizer1).to receive(:perform_available_cancellations!)

      subject.execute
    end
  end

  context "when thresholds are injected" do
    it "should forward different timeouts and batch sizes" do
      config[:timeout] = fixed_timeout.advance(days: positive_int)
      config[:batch_size] = fixed_batch_size + positive_int
      repository_params[:time] = config[:timeout]
      repository_params[:limit] = config[:batch_size]

      expect(repository).to receive(:older_than).with(repository_params).and_return([])

      subject.execute
    end

    it "should request the repository according to the batch size" do
      config[:batch_size] = 1
      repository_params[:limit] = 1

      cancellation_configs1 = {inquiry_category1_id => :timed_out}
      cancellation_configs2 = {inquiry_category3_id => :timed_out}
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs1).and_return(finalizer1)
      second_finalizer = instance_double(finalization_class)
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs2).and_return(second_finalizer)
      repo_return_sequence.([inquiry_category1], [inquiry_category3], [])

      expect(finalizer1).to receive(:perform_available_cancellations!).ordered
      expect(second_finalizer).to receive(:perform_available_cancellations!).ordered

      subject.execute
    end

    it "should accept an execution limit" do
      config[:execution_limit] = 1

      cancellation_configs1 = {inquiry_category1_id => :timed_out}
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs1).and_return(finalizer1)
      allow(finalizer1).to receive(:perform_available_cancellations!)

      cancellation_configs2 = {inquiry_category2_id => :timed_out}
      allow(finalization_class).to receive(:new).with(inquiry2, cancellation_configs2).and_return(finalizer2)

      repo_return_sequence.([inquiry_category1, inquiry_category2], [])

      expect(finalizer1).to receive(:perform_available_cancellations!)
      expect(finalizer2).not_to receive(:perform_available_cancellations!)

      subject.execute
    end

    context "when an error occurs" do
      it "should not reprocess the erroneous inquiry categories / loop infinite" do
        # For whatever reason, it could happen, that the repository returns the same inquiry category over and over
        # again. In a naive implementation, this leads to an endless loop, which has to be avoided.

        cancellation_configs = {inquiry_category1_id => :timed_out}
        allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs).and_return(finalizer1)
        repo_return_sequence.([inquiry_category1]) # This makes it return the same collection over and over.

        expect(finalizer1).to receive(:perform_available_cancellations!).at_most(:once)

        subject.execute
      end
    end
  end

  context "when batch information is logged" do
    let(:cancellation_configs) { {inquiry_category1_id => :timed_out} }

    before do
      allow(finalization_class).to receive(:new).with(inquiry1, cancellation_configs).and_return(finalizer1)
      allow(finalizer1).to receive(:perform_available_cancellations!)
      allow(logger).to receive(:info).with(String)
    end

    it "should log the start" do
      repo_return_sequence.([])
      expect(logger).to receive(:info).with("----- Start cancelling old inquiry categories... -----")
      subject.execute
    end

    it "should log the end with a summary" do
      repo_return_sequence.([])
      expect(logger).to receive(:info).with(match(/----- Done. Processed 0 inquiry categories in \d+ seconds. -----/))
      subject.execute
    end

    it "should log the end with a summary and the processed count" do
      repo_return_sequence.([inquiry_category1], [])
      expect(logger).to receive(:info).with(match(/----- Done. Processed 1 inquiry categories in \d+ seconds. -----/))
      subject.execute
    end

    context "when an error occurs" do
      before do
        repo_return_sequence.([inquiry_category1], [])
        allow(finalizer1).to receive(:perform_available_cancellations!).and_raise("sample error")
      end

      it "should log the error" do
        expect(logger).to receive(:error).with(String)
        subject.execute
      end

      it "should notify about the error" do
        allow(logger).to receive(:error).with(String)
        expect(Raven).to receive(:capture_exception).with(StandardError, extra: Hash)
        subject.execute
      end
    end
  end
end
