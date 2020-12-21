# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/interactors/find_plans"

RSpec.describe Offers::Constituents::ManualCreation::Interactors::FindPlans do
  context "invalid category_ident provided" do
    it "returns error" do
      result = described_class.new.call("fake-ident")
      expect(result).not_to be_success
      expect(result.errors).not_to be_empty
    end
  end

  context "with valid category_ident" do
    let(:plans) { double(:plans) }
    let(:category_ident) { "12345678" }

    it "exposes plans" do
      expect_any_instance_of(
        Offers::Constituents::ManualCreation::Repositories::PlanRepository
      ).to receive(:active_plans_for_category).with(category_ident).and_return(plans)

      expect(described_class.new.call(category_ident).plans).to eq plans
    end
  end
end
