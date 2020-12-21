# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::HouseholdContents::HouseholdAutomationContext do
  let(:candidate_context) { described_class.new(double) }

  describe "public instance methods" do
    context "responds to its methods" do
      it { expect(candidate_context).to respond_to(:applicable?) }
    end

    context "executes methods correctly" do
      context "#applicable?" do
        let(:candidate_context) { described_class.new(described_class) }

        it "returns false if user situation isn't valid" do
          allow_any_instance_of(described_class).to receive(:valid?) { false }
          allow_any_instance_of(described_class)
            .to receive(:comparison_results_are_valid?).and_return(true)

          expect(candidate_context.applicable?).to be_falsy
        end

        it "returns false if comparison results aren't valid" do
          allow_any_instance_of(described_class).to receive(:valid?) { true }
          allow_any_instance_of(described_class)
            .to receive(:comparison_results_are_valid?).and_return(false)

          expect(candidate_context.applicable?).to be_falsy
        end

        it "returns true if user situation and comparison results are valid" do
          allow_any_instance_of(described_class).to receive(:valid?) { true }
          allow_any_instance_of(described_class)
            .to receive(:comparison_results_are_valid?).and_return(true)

          expect(candidate_context.applicable?).to be_truthy
        end
      end
    end
  end
end
