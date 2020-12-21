# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Users::JourneyEvents::RatingModalTriggeredValidator do
  let(:error_class) { Domain::Users::JourneyEvents::EventPayloadError }
  let(:error_message) { subject.error_message }

  it "should not raise, if the payload is correct" do
    expect { subject.validate(payload: {"cause" => "string value"}) }.not_to raise_error
  end

  it "should raise, if the payload is empty" do
    expect { subject.validate(payload: {}) }.to raise_error(error_class, error_message)
  end

  it "should raise, if the payload key is empty" do
    expect { subject.validate(payload: {"cause" => nil}) }.to raise_error(error_class, error_message)
  end

  it "should raise, if the payload key is not a string" do
    expect { subject.validate(payload: {"cause" => 1}) }.to raise_error(error_class, error_message)
  end

  it "should raise, if the payload key is not a string again" do
    expect { subject.validate(payload: {"cause" => [1]}) }.to raise_error(error_class, error_message)
  end
end
