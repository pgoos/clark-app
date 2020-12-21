# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/repositories/opportunity_repository"
require "composites/offers/constituents/manual_creation/entities/offer_option"

RSpec.describe Offers::Constituents::ManualCreation::Repositories::OpportunityRepository, :integration do
  subject { described_class.new }

  describe "#find_opportunity_details" do
    let(:opportunity) { create(:opportunity_with_offer) }

    context "when opportunity exists" do
      it "returns entity" do
        result = subject.find_opportunity_details(id: opportunity.id)

        expect(result[:id]).to eq opportunity.id
        expect(result[:mandate_id]).to eq opportunity.mandate_id
        expect(result[:state]).to eq opportunity.state

        expect(result[:category_id]).to eq opportunity.category.id
        expect(result[:category_ident]).to eq opportunity.category.ident
        expect(result[:category_name]).to eq opportunity.category.name

        expect(result[:offer_id]).to eq opportunity.offer.id
        expect(result[:offer_rule_id]).to eq opportunity.offer.offer_rule_id
        expect(result[:offer_state]).to eq opportunity.offer.state
        expect(result[:displayed_coverage_features]).to eq opportunity.offer.displayed_coverage_features
        expect(result[:active_offer_selected]).to eq opportunity.offer.active_offer_selected
        expect(result[:customer_name]).to eq opportunity.mandate.name
        expect(result[:note_to_customer]).to eq opportunity.offer.note_to_customer

        expect(result[:offer_options].count).to eq 3
        expect(result[:offer_options].first).to be_a(Offers::Constituents::ManualCreation::Entities::OfferOption)
      end
    end

    context "when opportunity does not exist" do
      it "returns nil" do
        expect(subject.find_opportunity_details(id: 111)).to eq(nil)
      end
    end
  end
end
