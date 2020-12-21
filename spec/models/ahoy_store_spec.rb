# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ahoy::Store, type: :model do
  let!(:store) { Ahoy::Store.new({}) }

  it "should fail if everything is wrong" do
    allow(store).to receive(:request_path).and_return("something/tracking/adjust/event/somethingelse")
    allow(store).to receive(:request_headers).and_return("User-Agent" => "Prometheus")

    expect(store.exclude?).to eq(true)
  end

  it "should fail if request path is wrong" do
    allow(store).to receive(:request_path).and_return("something/tracking/adjust/event/somethingelse")
    allow(store).to receive(:request_headers).and_return("User-Agent" => "normal header")

    expect(store.exclude?).to eq(true)
  end

  it "should fail if header is wrong" do
    allow(store).to receive(:request_path).and_return("normal/path")
    allow(store).to receive(:request_headers).and_return("User-Agent" => "Prometheus")

    expect(store.exclude?).to eq(true)
  end

  it "should succeed if everything is ok" do
    allow(store).to receive(:request_path).and_return("normal/path")
    allow(store).to receive(:request_headers).and_return("User-Agent" => "normal header")

    expect(store.exclude?).to eq(false)
  end

  it "should succeed if there is no user agent" do
    allow(store).to receive(:request_path).and_return("normal/path")
    allow(store).to receive(:request_headers).and_return("User-Agent" => nil)

    expect(store.exclude?).to eq(false)
  end
end
