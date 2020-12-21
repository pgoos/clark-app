# frozen_string_literal: true

require "rails_helper"
require "composites/carrier"

RSpec.describe Carrier do
  let(:result) { instance_double(Utils::Interactor::Result) }

  describe "#create_customer", :integration do
    let(:customer) { instance_double(Carrier::Entities::Customer, id: 1) }
    let(:create_customer) do
      instance_double(Carrier::Constituents::Arisecur::Interactors::CreateCustomer, call: result)
    end

    before do
      allow(Carrier::Constituents::Arisecur::Interactors::CreateCustomer)
        .to receive(:new)
        .and_return(create_customer)
    end

    it "calls proper interactor" do
      expect(create_customer).to receive(:call).with(customer.id)
      described_class.create_customer(customer.id)
    end
  end

  describe "#stock_transfer", :integration do
    let(:product) { instance_double(Carrier::Entities::Product, id: 1) }
    let(:stock_transfer) { instance_double(Carrier::Constituents::Arisecur::Interactors::StockTransfer, call: result) }

    before do
      allow(Carrier::Constituents::Arisecur::Interactors::StockTransfer)
        .to receive(:new)
        .and_return(stock_transfer)
    end

    it "calls proper interactor" do
      expect(stock_transfer).to receive(:call).with(product.id)
      described_class.stock_transfer(product.id)
    end
  end
end
