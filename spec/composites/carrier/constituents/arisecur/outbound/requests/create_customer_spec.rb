# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/outbound/requests/create_customer"
require "./spec/composites/carrier/constituents/arisecur/outbound/requests/response_methods"

RSpec.describe Carrier::Constituents::Arisecur::Outbound::Requests::CreateCustomer do
  let(:attributes) do
    {
      first_name: "Test First",
      last_name: "Test Last",
      birthdate: "1990-01-01",
      gender: "male",
      email: "tak@tak.com"
    }
  end
  let(:request) { described_class.new(attributes) }
  let(:response) { double(:response, success?: true, body: "{\"Id\":\"1\"}") }
  let(:body) do
    {
      Anrede: "1",
      Kontaktdaten: [
        { Kontext: "privat", Typ: "email", Value: "tak@tak.com" }
      ],
      Person: {
        Geburtsdatum: "1990-01-01",
        Nachname: "Test Last",
        Typ: "natuerlich",
        Vorname: "Test First"
      }
    }
  end
  let(:options) { { request_type: :post, url: "kunden", body: body } }

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
