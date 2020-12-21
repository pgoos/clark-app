# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Cost::Adwords::GdnUacParser do
  let(:parser_factory) { Domain::Cost::AdvertiserCostParser.new }
  let(:vendors) { parser_factory.allowed_vendors }

  it "should be connected to the factory" do
    expect(vendors).to include(described_class.vendor)
  end
end
