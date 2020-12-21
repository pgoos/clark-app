# frozen_string_literal: true

require "rails_helper"

RSpec.describe Batch do
  it "should execute a block" do
    expect(Batch.handle_errors(nil) do
      1
    end).to eq(1)
  end

  it "should handle an exception" do
    expect {
      Batch.handle_errors(nil) { raise "test exception" }
    }.not_to raise_error
  end

  it "should return nil, if an exception got being raised" do
    expect(Batch.handle_errors(nil) { raise "test exception" }).to be_nil
  end

  it "should raise a batch error, if no block is given" do
    expect {
      Batch.handle_errors(nil)
    }.to raise_error(Batch::BatchError)
  end

  it "should log the context" do
    context = {some: "object"}
    e       = RuntimeError.new("test exception")
    mess    = ["A batch error occurred! Context: >>>#{context.inspect}<<<", e]

    match = /#{mess.join("\n")}.*/
    expect(Rails).to receive_message_chain(:logger, :error).with(matching(match))

    Batch.handle_errors(context) { raise e }
  end

  it "uses an injected logger" do
    logger = n_double("logger")
    expect(logger).to receive(:error).with(String)
    context = {logger: logger}
    e       = RuntimeError.new("test exception")
    Batch.handle_errors(context) { raise e }
  end

  context "Sentry" do
    it "should notify Sentry" do
      expect(Raven).to receive(:capture_exception).with(a_kind_of(StandardError))
      Batch.handle_errors(nil) { raise "test exception" }
    end

    # known issue:
    # https://bitbucket.org/mailchimp/mandrill-api-ruby/pull-requests/4/change-base-class-for-all-errors-to/diff
    it "should notify Sentry also about mandrill errors" do
      expect(Raven).to receive(:capture_exception).with(a_kind_of(Mandrill::Error))
      Batch.handle_errors(nil) { raise Mandrill::Error }
    end

    it "should send class and id of models, if given in the context" do
      model1 = create(:mandate)
      model2 = create(:category)
      expect(Raven).to receive(:capture_exception).with(a_kind_of(RuntimeError), extra: {
        mandate: model1.id,
        category: model2.id
      })
      Batch.handle_errors(model1: model1, model2: model2) { raise "test exception" }
    end

    it "should send class and id of models, if given in the context" do
      other_object = "just a string"
      expect(Raven).to receive(:capture_exception).with(a_kind_of(RuntimeError), extra: {
        key_on_nil: {
          class: nil.class.name,
          object_id: nil.object_id
        },
        some_object: {
          class: other_object.class.name,
          object_id: other_object.object_id
        }
      })
      Batch.handle_errors(key_on_nil: nil, some_object: other_object) { raise "test exception" }
    end
  end
end
