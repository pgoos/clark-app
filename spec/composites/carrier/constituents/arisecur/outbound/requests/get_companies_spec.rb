# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/outbound/requests/get_companies"
require "./spec/composites/carrier/constituents/arisecur/outbound/requests/response_methods"

RSpec.describe Carrier::Constituents::Arisecur::Outbound::Requests::GetCompanies do
  let(:request) { described_class.new }
  let(:body) { [{ "Text" => "Test Arisecur", "Value" => "testarisecur" }] }
  let(:response) { double(:response, success?: true, body: body) }
  let(:options) { { request_type: :get, url: "gesellschaften" } }

  before do
    allow_any_instance_of(Carrier::Constituents::Arisecur::Outbound::Client)
      .to receive(:call).with(options).and_return(response)
    request.call
  end

  include_examples "response_methods"

  describe "#call" do
    it "should execute call method on client" do
      expect(request.instance_variable_get(:@client))
        .to have_received(:call)
        .with(options)
    end
  end
end
