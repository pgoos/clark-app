# frozen_string_literal: true

require "rails_helper"

require "composites/sales/constituents/opportunity/repositories/opportunity_repository"
require "composites/sales/constituents/opportunity/interactors/find_opportunity"

RSpec.describe Sales::Constituents::Opportunity::Interactors::FindOpportunity do
  let(:interactor) { described_class.new(opportunities_repo: double_opportunities_repo) }
  let(:double_opportunities_repo) do
    instance_double(Sales::Constituents::Opportunity::Repositories::OpportunityRepository)
  end

  describe "#call" do
    let(:mandate) { double("Mandate", id: 1) }
    let(:opportunity) { double("Opportunity", id: 1) }

    it "call repository with right arguments" do
      expect(double_opportunities_repo).to receive(:find).with(mandate.id, opportunity.id)

      interactor.call(mandate.id, opportunity.id)
    end

    it "raise a not found error" do
      allow(double_opportunities_repo)
        .to receive(:find).with(mandate.id, opportunity.id).and_raise(Utils::Repository::Errors::NotFoundError)

      result = interactor.call(mandate.id, opportunity.id)
      result.on_failure { |err| err.is_a?(Interactors::Errors::NotFoundError) }
    end
  end
end
