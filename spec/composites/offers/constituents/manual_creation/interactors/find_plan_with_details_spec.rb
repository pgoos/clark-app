# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/interactors/find_plan_with_details"

RSpec.describe Offers::Constituents::ManualCreation::Interactors::FindPlanWithDetails do
  context "invalid plan ident provided" do
    it "returns error" do
      result = described_class.new.call("fake-ident")
      expect(result).not_to be_success
      expect(result.errors).not_to be_empty
    end
  end

  context "with valid plan ident" do
    let(:plan) { double(:plan, ident: "ident") }

    it "triggers 'plan_with_details' method" do
      expect_any_instance_of(Offers::Constituents::ManualCreation::Repositories::PlanRepository)
        .to receive(:plan_with_details)
        .with(plan.ident)

      described_class.new.call(plan.ident)
    end
  end
end
