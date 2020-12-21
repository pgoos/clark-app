# frozen_string_literal: true

require "rails_helper"

describe AbTesting::Tracker do
  let(:tracker) { double :tracker, track: nil }

  it "tracks a visit" do
    expect(tracker).to receive(:track).with(
      "experiment_on",
      experiment_name: "EXPERIMENT_NAME",
      value:           "VAR_NAME",
      url:             "VAR_URL"
    )
    described_class.track(tracker, "EXPERIMENT_NAME", name: "VAR_NAME", url: "VAR_URL")
  end
end
