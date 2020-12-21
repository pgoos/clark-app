# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Users::JourneyEvents::RatingModalRatedValidator do
  let(:error_class) { Domain::Users::JourneyEvents::EventPayloadError }
  let(:error_message) { subject.error_message }

  it "should not raise, if the payload is correct" do
    expect { subject.validate(payload: {"positive" => "false"}) }.not_to raise_error
    expect { subject.validate(payload: {"positive" => "true"}) }.not_to raise_error
  end

  it "should raise, if the rating is too low" do
    expect { subject.validate(payload: {"positive" => "1"}) }.to raise_error(error_class, error_message)
  end

  it "should raise, if the payload is empty" do
    expect { subject.validate(payload: {}) }.to raise_error(error_class, error_message)
  end

  it "should raise, if the payload key is empty" do
    expect { subject.validate(payload: {"positive" => nil}) }.to raise_error(error_class, error_message)
  end

  it "should raise, if the payload key is not an integer" do
    expect { subject.validate(payload: {"cause" => "1"}) }.to raise_error(error_class, error_message)
  end

  it "should raise, if the payload key is not a integer again" do
    expect { subject.validate(payload: {"cause" => [1]}) }.to raise_error(error_class, error_message)
  end
end
