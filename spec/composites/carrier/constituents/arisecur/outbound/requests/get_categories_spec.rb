# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/outbound/requests/get_categories"
require "./spec/composites/carrier/constituents/arisecur/outbound/requests/response_methods"

RSpec.describe Carrier::Constituents::Arisecur::Outbound::Requests::GetCategories do
  let(:request) { described_class.new }
  let(:body) { [{ "Text" => "Test Arisecur", "Value" => "testarisecur" }] }
  let(:response) { double(:response, success?: true, body: body) }
  let(:options) do
    {
      request_type: :get,
      url: "https://testhost.com/test_mandant/broker/test_version/rest/sparten"
    }
  end

  before do
    stub_const(
      "ENV",
      {
        "ARISECUR_API_HOST" => "https://testhost.com",
        "ARISECUR_API_MANDANT" => "test_mandant",
        "ARISECUR_API_VERSION" => "test_version"
      }
    )
    allow_any_instance_of(Carrier::Constituents::Arisecur::Outbound::Client)
      .to receive(:call)
      .with(options, custom_url: true)
      .and_return(response)
    request.call
  end

  include_examples "response_methods"

  describe "#call" do
    it "should execute call method on client" do
      expect(request.instance_variable_get(:@client))
        .to have_received(:call)
        .with(options, custom_url: true)
    end
  end
end
