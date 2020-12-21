# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogExpensiveMethods do
  class SampleCaller
    include LogExpensiveMethods

    def caller
      []
    end
  end

  subject do
    SampleCaller.new
  end

  it "should send a Raven in production, if called" do
    allow(Rails).to receive(:env).and_return("production")
    expected_hash = {
      error_class:   SampleCaller.name
    }

    expect(Raven).to receive(:capture_message).with("expensive cms method called", extra: expected_hash).and_call_original
    subject.log_callers
  end
end
