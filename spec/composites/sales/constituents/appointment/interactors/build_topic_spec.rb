# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Appointment::Interactors::BuildTopic do
  describe "#call" do
    context "when topic_type is Opportunity" do
      let(:topic_type) { "Opportunity" }

      context "when strategy is force-create" do
        let(:strategy) do
          {
            name: "force-create",
            params: {
              category_id: 1,
              sales_campaign_id: 1,
              source_description: "Summer 2020"
            }
          }
        end

        it "call Opportunity repository with correct params" do
          expect_any_instance_of(
            Sales::Constituents::Opportunity::Repositories::OpportunityRepository
          ).to receive(:create_opportunity!).with(
            1,
            strategy[:params]
          )

          described_class.new.call(topic_type, strategy, 1)
        end
      end
    end
  end
end
