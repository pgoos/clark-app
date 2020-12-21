# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/outbound/requests/create_product"
require "./spec/composites/carrier/constituents/arisecur/outbound/requests/response_methods"

RSpec.describe Carrier::Constituents::Arisecur::Outbound::Requests::CreateProduct do
  let(:customer) { create(:mandate) }
  let!(:carrier_data) { create(:carrier_data, customer_number: "123", mandate_id: customer.id) }
  let(:company_mapper) do
    instance_double(Carrier::Constituents::Arisecur::Mappers::CompanyMapper, arisecur_ident: "A0000")
  end
  let(:category_mapper) do
    instance_double(Carrier::Constituents::Arisecur::Mappers::CategoryMapper, arisecur_ident: "A55")
  end
  let(:attributes) do
    {
      product_number: 123,
      customer_id: customer.id,
      premium_price: 123_456,
      payment_method: 5,
      end_of_contract: "2021-01-01",
      customer_number: 123,
      subcompany_name: "test company",
      category_name: "test category"
    }
  end
  let(:request) { described_class.new(attributes) }
  let(:response) { double(:response, success?: true, body: "{\"Id\":\"1\"}") }
  let(:body) do
    {
      "Status": "X",
        "Gesellschaft": "A0000",
        "Sparte": "A55",
        "Beitrag": {
          "Brutto": 1234.56,
            "Zahlweise": "1"
        },
        "Laufzeit": {
          "Beginn": nil,
            "Ablauf": "2021-01-01"
        },
        "Versicherungsscheinnummer": 123
    }
  end
  let(:options) { { request_type: :post, url: "kunden/123/vertraege", body: body } }

  before do
    allow(Carrier::Constituents::Arisecur::Mappers::CompanyMapper)
      .to receive(:new)
      .with(attributes[:subcompany_name])
      .and_return company_mapper
    allow(Carrier::Constituents::Arisecur::Mappers::CategoryMapper)
      .to receive(:new)
      .with(attributes[:category_name])
      .and_return category_mapper
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
