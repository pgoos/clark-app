require 'rails_helper'
require 'ostruct'

RSpec.describe Domain::OpportunityGeneration::OgBlacklistedPhv do
  let!(:admin) { create(:admin) }

  let(:subject) { described_class }
  let(:expected_name) { "OG_BLACKLISTED_PHV" }
  let(:limit) { 50 }

  let(:intent_class) { Platform::RuleEngineV3::Flows::MessageToQuestionnaire }

  let(:mandate) { create(:mandate, state: "accepted") }
  context "run" do
    before do
      sub_company = create(:subcompany, ident: "some_company", pools: [])
      category = create(:category, ident: described_class::CATEGORY_IDENT)
      plan = create(:plan, subcompany: sub_company, category: category)
      create(:product,
                         mandate:           mandate,
                         plan:              plan,
                         contract_ended_at: described_class::END_DATE_RANGE.first + 1.hour,
                         state:             "details_available")
    end

    let(:feature_name) { "AUTOMATED_#{expected_name.upcase}" }
    let!(:feature_switch) {
      feature = FeatureSwitch.find_or_create_by(key: feature_name)
      feature.update(active: true)
      feature.save

      feature
    }

    it "operates on candidates" do
      rule = described_class

      expect(rule.candidates.count).to eq(1)
      intents = rule.apply(false)

      expect(intents.count).to eq(1)
      expect(intents.first).to be_a(intent_class)
    end

    it "does not operate twice on candidates" do
      rule = described_class

      candidate = rule.candidates.first
      expect(rule.candidates.count).to eq(1)
      RuleHelper.simulate_execution(subject, candidate, candidate.mandate)
      expect(rule.candidates.count).to eq(0)
    end
  end
end
