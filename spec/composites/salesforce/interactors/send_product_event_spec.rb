# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/send_product_event"

RSpec.describe Salesforce::Interactors::SendProductEvent, :integration do
  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:company) { create(:company, name: "Company") }
  let!(:plan) { create(:plan, company: company) }
  let!(:product) { create(:product, { contract_ended_at: DateTime.current, company: company }) }
  let!(:offer) { create(:offer) }
  let!(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product: product, offer_id: offer) }
  let!(:offer_option) { create(:offer_option, product: product, offer: offer) }

  context "create" do
    it "is successful" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(product.id, "Product", "created")
      expect(result).to be_successful
    end

    it "is success with nil" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(10_000, "Product", "created")
      expect(result).to be_successful
    end

    it "is error" do
      object = described_class.new
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
      expect {
        object.call(product.id, "Product", "created")
      }.to raise_error(Salesforce::Outbound::Errors::BadRequestError)
    end
  end

  context "update" do
    it "is successful" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(product.id, "Product", "updated")
      expect(result).to be_successful
    end

    it "is success with nil" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(10_000, "Product", "updated")
      expect(result).to be_successful
    end

    it "is error" do
      object = described_class.new
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
      expect {
        object.call(product.id, "Product", "updated")
      }.to raise_error(Salesforce::Outbound::Errors::BadRequestError)
    end
  end
end
