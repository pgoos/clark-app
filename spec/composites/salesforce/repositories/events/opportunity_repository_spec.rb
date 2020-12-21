# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/events/opportunity_repository"

RSpec.describe Salesforce::Repositories::Events::OpportunityRepository do
  subject(:repository) { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:product) { create(:product) }
  let!(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product: product) }

  describe "#find" do
    it "returns event" do
      event = repository.find(opportunity.id, "Opportunity", "sold")
      expect(event.id).to eq opportunity.id
      expect(event.country).to eq "de"
      expect(event.aggregate_type).to eq "opportunity"
      expect(event.aggregate_id).to eq opportunity.id
      expect(event.sequence).to eq 1
      expect(event.type).to eq "opportunity-won"
      expect(event.revision).to eq 1
      expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
    end

    context "when opportunity does not have a product" do
      before do
        opportunity.sold_product = nil
        opportunity.save!
      end

      it "returns event" do
        event = repository.find(opportunity.id, "opportunity", "sold")
        expect(event.id).to eq opportunity.id
        expect(event.country).to eq "de"
        expect(event.aggregate_type).to eq "opportunity"
        expect(event.aggregate_id).to eq opportunity.id
        expect(event.sequence).to eq 1
        expect(event.type).to eq "opportunity-won"
        expect(event.revision).to eq 1
        expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
      end
    end

    context "when opportunity does not exist" do
      it "returns nil" do
        expect(repository.find(9999, "Opportunity", "sold")).to be_nil
      end
    end
  end
end
