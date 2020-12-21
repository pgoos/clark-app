# frozen_string_literal: true

require "rails_helper"

RSpec.describe NPSCyclesRepository, :integration do
  describe "#open_cycle?" do
    context "when cycle is open" do
      before { create(:nps_cycle, :open, end_at: Time.now + 2.days) }

      it "returns true" do
        expect(described_class.open_cycle?).to be true
      end
    end

    context "when there is no open cycle" do
      it "returns false" do
        expect(described_class.open_cycle?).to be false
      end
    end
  end
end
