# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/interactors/find_opportunity_details"

RSpec.describe Offers::Constituents::ManualCreation::Interactors::FindOpportunityDetails do
  context "invalid id provided" do
    it "returns error" do
      result = described_class.new.call(id: 111)
      expect(result).not_to be_success
      expect(result.errors).not_to be_empty
    end
  end

  context "with valid id" do
    let(:id) { 1 }
    let(:opportunity) { double(:opportunity) }

    it "exposes opportunity" do
      expect_any_instance_of(
        Offers::Constituents::ManualCreation::Repositories::OpportunityRepository
      ).to receive(:find_opportunity_details).with(id).and_return(opportunity)

      expect(described_class.new.call(id).opportunity).to eq opportunity
    end
  end
end
