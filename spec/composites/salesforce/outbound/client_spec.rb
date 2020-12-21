# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/outbound/client"
require "composites/salesforce/outbound/errors"

RSpec.describe Salesforce::Outbound::Client do
  subject { described_class.new }

  it "returns payload form request" do
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 200))
    expect(subject.call({ request_type: :post }).status).to eq 200
  end

  it "raises error form wrong request" do
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
    expect { subject.call({}) }.to raise_error Salesforce::Outbound::Errors::BadRequestError
  end
end
