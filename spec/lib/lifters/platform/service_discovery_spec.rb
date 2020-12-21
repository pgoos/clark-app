# frozen_string_literal: true
require "rails_helper"

RSpec.describe Platform::ServiceDiscovery do
  let(:env)  { double(Rails.env) }
  let(:host) { Settings.messenger.socket_server.messages_api_end_point || "localhost:3000" }

  context "default" do
    it { expect(described_class.new.messenger_socket).to eq("wss://#{host}/") }
    it { expect(described_class.new.messenger_rest).to eq("https://#{host}/messages") }
  end

  context "development" do
    let(:subject) { described_class.new(env, "192.168.16.40:3000") }

    before do
      allow(env).to receive(:development?).and_return(true)
    end

    it { expect(subject.messenger_socket).to eq("ws://192.168.16.40:8801/") }
    it { expect(subject.messenger_rest).to eq("http://192.168.16.40:9901/messages") }
  end

  context "production" do
    let(:subject) { described_class.new(env, "socket.clark.de") }

    before do
      allow(env).to receive(:development?).and_return(false)
    end

    it { expect(subject.messenger_socket).to eq("wss://socket.clark.de/") }
    it { expect(subject.messenger_rest).to eq("https://socket.clark.de/messages") }
  end
end
