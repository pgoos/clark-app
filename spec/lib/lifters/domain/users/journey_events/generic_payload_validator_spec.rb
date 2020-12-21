# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Users::JourneyEvents::GenericPayloadValidator do
  let(:error_class) { Domain::Users::JourneyEvents::EventPayloadError }

  it "should be valid, if an empty hash is given" do
    expect(subject.validate(payload: {})).to be(nil)
  end

  it "should raise an error, if the payload is nil" do
    message = "Event error: Payload can't be nil!"
    expect { subject.validate(payload: nil) }.to raise_error(error_class, message)
  end

  it "should raise an expressive error, if the payload contains values" do
    message = "Implementation error: Implement a payload validator!"
    expect { subject.validate(payload: {"key" => nil}) }.to raise_error(error_class, message)
  end
end
