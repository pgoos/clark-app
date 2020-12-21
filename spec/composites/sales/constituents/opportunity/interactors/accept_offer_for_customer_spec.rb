# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::AcceptOfferForCustomer do
  describe "#call" do
    context "when called with correct parameters" do
      let(:opportunity_id) { 1 }
      let(:product_id) { 2 }

      it "calls accept_offer_and_complete! method from OpportunityRepository" do
        expect_any_instance_of(
          Sales::Constituents::Opportunity::Repositories::OpportunityRepository
        ).to receive(:accept_offer!).with(opportunity_id, product_id)

        subject.call(opportunity_id, product_id)
      end
    end

    context "when called with incorrect parameters" do
      let(:opportunity_id) { 1 }
      let(:product_id) { 2 }

      it "does not raise error but returns sucess: false" do
        result = subject.call(opportunity_id, product_id)

        expect(result).not_to be_success
      end
    end
  end
end
