# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Interactions::OutgoingRepository do
  let(:subject) { described_class }
  let(:now) { Time.current }
  let(:yesterday) { now - 1.day }

  let(:mandates) { create_list(:mandate, 2) }

  let(:mandate1) { mandates.first }
  let!(:interaction1) { create(:interaction_advice, direction: "out", mandate: mandate1, created_at: now) }
  let!(:interaction2) { create(:interaction_email, direction: "out", mandate: mandate1, created_at: yesterday) }

  let(:mandate2) { mandates.last }
  let!(:interaction3) { create(:interaction_advice, direction: "out", mandate: mandate2, created_at: yesterday) }
  let!(:interaction4) { create(:interaction_email, direction: "out", mandate: mandate2, created_at: now) }
  let!(:interaction5) { create(:interaction_email, direction: "out", mandate: mandate2, created_at: yesterday) }
  let!(:interaction6) { create(:interaction_advice, direction: "out", mandate: mandate2, created_at: 1.minute.ago) }

  describe ".last_interactions_by_mandate" do
    it "return list of interaction for provided mandate ids" do
      result = subject.last_interactions_by_mandate([mandate1.id, mandate2.id])
      expect(result.map(&:id)).to match_array([interaction1.id, interaction4.id])
    end

    it "retuns the exactly number of mandates" do
      result = subject.last_interactions_by_mandate(mandates.map(&:id))
      expect(result.count).to eq(mandates.count)
    end

    it "return empty array if no mandate ids given" do
      result = subject.last_interactions_by_mandate([])
      expect(result.map(&:id)).to eq([])
    end
  end
end
