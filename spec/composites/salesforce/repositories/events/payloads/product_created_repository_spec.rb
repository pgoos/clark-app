# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/events/payloads/product_created_repository"

RSpec.describe Salesforce::Repositories::Events::Payloads::ProductCreatedRepository do
  subject(:repository) { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:company) { create(:company, name: "Company") }
  let!(:plan) { create(:plan, company: company) }
  let!(:product) { create(:product, { contract_ended_at: DateTime.current, company: company }) }
  let!(:offer) { create(:offer) }
  let!(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product: product, offer_id: offer) }
  let!(:offer_option) { create(:offer_option, product: product, offer: offer) }

  describe "#wrap" do
    it "returns product created event" do
      event = repository.wrap(product)
      expect(event.id).to eq product.id
      expect(event.customer_id).to eq product.mandate_id
      expect(event.opportunity_id).to eq Opportunity.find_by(sold_product_id: product.id)&.id
      expect(event.category_id).to eq product.category.id
      expect(event.category_name).to eq product.category.name
      expect(event.company_name).to eq product.company.name
      expect(event.plan_name).to eq product.plan.name
      expect(event.sold_by).to eq product.sold_by
      expect(event.product_state).to eq product.state
      expect(event.insurance_start_date).to eq product.contract_started_at&.rfc3339
      expect(event.insurance_end_date).to eq product.contract_ended_at&.rfc3339
      expect(event.insurance_number).to eq product.number
      expect(event.premium).to eq product.premium_price_cents
      expect(event.premium_period).to eq product.premium_period
      expect(event.date_of_maturity).to be_nil
      expect(event.management_fee).to eq 500
      expect(event.sales_fee).to eq 0.0
    end

    context "when event does not exist" do
      it "returns nil" do
        expect(repository.wrap(nil)).to be_nil
      end
    end
  end
end
