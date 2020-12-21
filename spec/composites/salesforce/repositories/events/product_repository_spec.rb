# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/events/product_repository"

RSpec.describe Salesforce::Repositories::Events::ProductRepository do
  subject(:repository) { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:company) { create(:company, name: "Company") }
  let!(:plan) { create(:plan, company: company) }
  let!(:product) { create(:product, { contract_ended_at: DateTime.current, company: company }) }
  let!(:offer) { create(:offer) }
  let!(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product: product, offer_id: offer) }
  let!(:offer_option) { create(:offer_option, product: product, offer: offer) }

  describe "#find" do
    it "returns created event" do
      event = repository.find(product.id, "Product", "created")
      expect(event.id).to eq product.id
      expect(event.country).to eq "de"
      expect(event.aggregate_type).to eq "product"
      expect(event.aggregate_id).to eq product.id
      expect(event.sequence).to eq 1
      expect(event.type).to eq "product-created"
      expect(event.revision).to eq 1
      expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
    end

    it "returns updated event" do
      event = repository.find(product.id, "Product", "updated")
      expect(event.id).to eq product.id
      expect(event.country).to eq "de"
      expect(event.aggregate_type).to eq "product"
      expect(event.aggregate_id).to eq product.id
      expect(event.sequence).to eq 1
      expect(event.type).to eq "product-updated"
      expect(event.revision).to eq 1
      expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
    end
  end
end
