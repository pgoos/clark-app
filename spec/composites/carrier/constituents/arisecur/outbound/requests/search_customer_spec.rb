# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/outbound/requests/search_customer"
require "./spec/composites/carrier/constituents/arisecur/outbound/requests/response_methods"

RSpec.describe Carrier::Constituents::Arisecur::Outbound::Requests::SearchCustomer do
  let(:customer_email) { "tak@tak.com" }
  let(:request) { described_class.new(customer_email) }
  let(:response) { double(:response, success?: true, body: "{\"Id\":\"1\"}") }
  let(:body) { { mail: customer_email } }
  let(:options) { { request_type: :post, url: "kunden/_search", body: body } }

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
