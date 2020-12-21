# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/exploration/repositories/opportunity_repository"

RSpec.describe Customer::Constituents::Exploration::Repositories::OpportunityRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#find_by_customer" do
    it "returns opportunity with aggregated data" do
      mandate = create(:mandate)
      opportunity = create(:opportunity, mandate: mandate)

      result = repo.find_by_customer(mandate.id)
      expect(result).to be_kind_of Customer::Constituents::Exploration::Entities::Opportunity
      expect(result.id).to eql(opportunity.id)
    end

    context "when opportunity does not exist" do
      it "returns nil" do
        expect(repo.find_by_customer(999)).to be_nil
      end
    end
  end
end
