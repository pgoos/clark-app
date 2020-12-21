# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::ApiPartners::Clients::MockClient do
  let(:subject) { described_class.new("test_partner") }
  let(:logger) { Logger.new("/dev/null") }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info).with(anything) do |msg|
      msg
    end
  end

  it "logs the right operation" do
    instance_methods = described_class.instance_methods - Object.instance_methods
    instance_methods.each do |method_name|
      log_msg = subject.send(method_name, anything)
      expect(log_msg).to include(method_name.to_s)
    end
  end

  it "calls logger info for all operations" do
    instance_methods = described_class.instance_methods - Object.instance_methods
    instance_methods.each do |method_name|
      expect(logger).to receive(:info)
      subject.send(method_name, anything)
    end
  end
end
