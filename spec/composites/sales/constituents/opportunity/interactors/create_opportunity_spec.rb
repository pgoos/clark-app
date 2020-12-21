# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::CreateOpportunity do
  describe "#call" do
    context "when called with correct parameters" do
      let(:params) do
        {
          category_id: 1,
          sales_campaign_id: 1,
          source_description: "welcome call"
        }
      end

      it "calls create_opportunity! method from OpportunityRepository" do
        expect_any_instance_of(
          Sales::Constituents::Opportunity::Repositories::OpportunityRepository
        ).to receive(:create_opportunity!).with(
          1,
          category_id: 1,
          sales_campaign_id: 1,
          source_description: "welcome call"
        )

        described_class.new.call(1, params)
      end
    end

    context "when called with incorrect parameters" do
      let(:params) do
        {
          category_id: 666,
          sales_campaign_id: 1,
          source_description: "welcome call"
        }
      end

      it "does not raise error but returns sucess: false" do
        result = described_class.new.call(1, params)

        expect(result.success?).to be_falsey
      end
    end
  end
end
