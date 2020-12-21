# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/events/payloads/opportunity_offer_accepted_repository"

RSpec.describe Salesforce::Repositories::Events::Payloads::OpportunityOfferAcceptedRepository do
  subject(:repository) { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:product) { create(:product) }
  let!(:offer) { create(:offer) }
  let!(:offer_option) { create(:offer_option, product: product, offer: offer) }
  let!(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product: product, offer: offer) }

  describe "#wrap" do
    it "returns opportunity accepted event" do
      event = repository.wrap(opportunity)
      expect(event.id).to eq opportunity.id
      expect(event.campaign_name).to eq opportunity.sales_campaign&.name
      expect(event.category_id).to eq opportunity.category_id
      expect(event.category_name).to eq opportunity.category.name
      expect(event.admin_email).to eq opportunity.admin.email
      expect(event.customer_id).to eq opportunity.mandate_id
      expect(event.offer_id).to eq opportunity.offer_id
      expect(event.source_description).to eq opportunity.source_description
      expect(event.welcome_call).to eq false
      expect(event).to be_kind_of Salesforce::Entities::Events::OpportunityOfferAccepted
    end

    context "when opportunity does not exist" do
      it "returns nil" do
        expect(repository.wrap(nil)).to be_nil
      end
    end
  end
end
