# frozen_string_literal: true

require "rails_helper"
require "composites/sales/constituents/opportunity/outbound/requests/aoa_ranks"

RSpec.describe Sales::Constituents::Opportunity::Outbound::Requests::AoaRanks do
  subject { described_class.new({}) }

  before do
    allow_any_instance_of(Sales::Constituents::Opportunity::Repositories::AoaSettingsRepository)
      .to receive(:aoa_api_url).and_return("https://aoa.test-staging.clark-de.flfinteche.de")
  end

  it "returns payload form request" do
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 201))
    subject.call
    expect(subject.response.status).to eq 201
  end

  it "raises error form wrong request" do
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
    expect { subject.call }.to raise_error Sales::Constituents::Opportunity::Outbound::Errors::BadRequestError
  end
end
