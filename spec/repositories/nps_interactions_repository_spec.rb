# frozen_string_literal: true

require "rails_helper"

RSpec.describe NPSInteractionsRepository, :integration do
  describe "#any_interaction_in_the_last_6_months?" do
    let(:mandate) { create(:mandate) }

    context "when there is an interaction" do
      before { create(:nps_interaction, mandate: mandate, created_at: 5.months.ago) }

      it "returns true" do
        expect(described_class.any_interaction_in_the_last_6_months?(mandate.id)).to be true
      end
    end

    context "when there is no interaction" do
      before { create(:nps_interaction, mandate: mandate, created_at: 6.months.ago - 1.day) }

      it "returns true" do
        expect(described_class.any_interaction_in_the_last_6_months?(mandate.id)).to be false
      end
    end
  end
end
