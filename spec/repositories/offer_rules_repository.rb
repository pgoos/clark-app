# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfferRulesRepository, :integration do
  context "#all_by" do
    let(:offer_automation_id) { create(:offer_automation).id }
    let(:names) { %w[rule-1 rule-2] }

    before do
      names.each { |name| create(:offer_rule, name: name, offer_automation_id: offer_automation_id) }
    end

    it "retrieves all offer_rules with matching idents" do
      offer_rules = described_class.all_sorted_by_ascending_name(offer_automation_id: offer_automation_id)

      expect(offer_rules.length).to be(2)
      expect(offer_rules.map(&:name)).to eq(names)
    end
  end
end
