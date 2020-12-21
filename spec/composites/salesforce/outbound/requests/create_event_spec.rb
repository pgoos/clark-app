# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/outbound/requests/create_event"

RSpec.describe Salesforce::Outbound::Requests::CreateEvent do
  subject { described_class.new({}) }

  it "returns payload form request" do
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 200))
    subject.call
    expect(subject.response.status).to eq 200
  end

  it "raises error form wrong request" do
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
    expect { subject.call }.to raise_error Salesforce::Outbound::Errors::BadRequestError
  end
end
