require "rails_helper"
require "ostruct"

RSpec.describe Domain::OpportunityGeneration::OgKfzHighCosts do
  let!(:admin) { create(:admin) }

  let(:subject) { described_class }
  let(:expected_name) { "OG_KFZ_HIGH_COSTS" }
  let(:limit) {}

  let(:intent_class) { Domain::Intents::PlayAdvice }

  context "run" do
    before do
      mandate = create(:mandate, state: "accepted")
      company = create(:company, ident: described_class::COMPANIES.first)
      category = create(:category, ident: described_class::CATEGORIES.first)
      plan = create(:plan, company: company, category: category)
      create(:product, mandate:           mandate,
                                   plan:              plan,
                                   contract_ended_at: described_class::LAST_DAY_OF_2016,
                                   state:             "details_available")
    end

    let(:feature_name) { "AUTOMATED_#{expected_name.upcase}" }
    let!(:feature_switch) {
      create(:feature_switch,
                         key:    feature_name,
                         active: true)
    }

    it "operates on candidates" do
      rule = described_class

      expect(rule.candidates.count).to eq(1)
      intents = rule.apply(false)

      expect(intents.count).to eq(1)
      expect(intents.first).to be_a(intent_class)
    end
  end
end
