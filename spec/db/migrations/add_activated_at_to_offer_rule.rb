# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "add_activated_at_to_offer_rule"

RSpec.describe AddActivatedAtToOfferRule, :integration do
  describe "#data" do
    let!(:offer_rules) do
      [
        create(:offer_rule),
        create(:active_offer_rule)
      ]
    end

    before do
      described_class.new.data
      offer_rules.each(&:reload)
    end

    it "sets activated_at for active rules" do
      expect(offer_rules[0].activated_at).to eq nil
      expect(offer_rules[1].activated_at).to eq offer_rules[1].updated_at
    end
  end
end
