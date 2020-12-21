# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/outbound/requests/transfer_signed_mandate"
require "./spec/composites/carrier/constituents/arisecur/outbound/requests/response_methods"

RSpec.describe Carrier::Constituents::Arisecur::Outbound::Requests::TransferSignedMandate do
  let(:attributes) do
    {
      id: 1,
        contract_number: "123",
        customer_number: "123",
        customer_id: 1,
        product_id: 1,
        state: "customer_created",
        signed_mandate_filename: "kunde-test.pdf",
        signed_mandate_path: "some/path/to/file.pdf"
    }
  end
  let(:request) { described_class.new(attributes) }
  let(:response) { double(:response, success?: true, body: "{\"Id\":\"1\"}") }
  let(:body) do
    {
      mode: "file",
        file:
         {
           src:
         "some/path/to/file.pdf"
         }
    }
  end
  let(:content_type) {
    "application/pdf; name=kunde-test.pdf"
  }
  let(:additional_header) {
    {
      "X-Dio-Tags" => "[\"Maklervollmacht\"]",
        "X-Dio-Typ" => "dokument",
         "X-Dio-Zuordnungen" => "[{\"Typ\":\"vertrag\",\"Id\":\"123\"}]"
    }
  }
  let(:options) do
    {
      request_type: :post,
      url: "kunden/123/archiveintraege",
      body: body,
      content_type: content_type,
      headers: additional_header
    }
  end

  before do
    allow_any_instance_of(Carrier::Constituents::Arisecur::Outbound::Client)
      .to receive(:call)
      .with(options)
      .and_return(response)
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
