# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::RavenPartners do
  it "cannot be initialised as it is a singleton class" do
    expect { described_class.new }.to raise_exception(NoMethodError)
  end

  it "returns a singleton instance of the class" do
    expect(described_class.instance).to be_a_kind_of(described_class)
  end

  it "exposes a new raven instance under sentry_logger method name" do
    expect(described_class.instance.sentry_logger).to be_a_kind_of(Raven::Instance)
  end
end
