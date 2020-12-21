# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/outbound/requests/set_customer_address"
require "./spec/composites/carrier/constituents/arisecur/outbound/requests/response_methods"

RSpec.describe Carrier::Constituents::Arisecur::Outbound::Requests::SetCustomerAddress do
  let(:customer) { create(:mandate) }
  let(:attributes) { customer.address.attributes.symbolize_keys.merge(customer_number: "1234") }
  let(:request) { described_class.new(attributes) }
  let(:response) { double(:response, success?: true, body: "{\"Id\":\"1\"}") }
  let(:body) do
    {
      "Typ": "hauptwohnsitz",
      "Strasse": "#{customer.address.street} #{customer.address.house_number}",
      "Postleitzahl": customer.address.zipcode,
      "Ort": customer.address.city,
      "Land": customer.country_code.downcase
    }
  end
  let(:options) { { request_type: :put, url: "kunden/1234/adressen/0", body: body } }

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
