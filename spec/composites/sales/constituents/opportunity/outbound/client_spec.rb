# frozen_string_literal: true

require "rails_helper"
require "composites/sales/constituents/opportunity/outbound/client"
require "composites/sales/constituents/opportunity/outbound/errors"

RSpec.describe Sales::Constituents::Opportunity::Outbound::Client do
  subject { described_class.new }

  it "returns payload form request" do
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 201))
    expect(subject.call({ request_type: :post }).status).to eq 201
  end

  it "raises error form wrong request" do
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
    expect { subject.call({}) }.to raise_error Sales::Constituents::Opportunity::Outbound::Errors::BadRequestError
  end
end
