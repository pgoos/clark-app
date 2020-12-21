require 'rails_helper'
require 'ostruct'

RSpec.describe Domain::OpportunityGeneration::OgProductContractEndBlacklist do
  # System prerequisites
  let!(:admin) { create(:admin) }

  # Rule metadate
  let(:subject) { described_class }
  let(:expected_name) { 'OG_PRODUCT_CONTRACT_END_BLACKLIST' }
  let(:limit) {}

  # Situation Specification
  let(:situation_class) { NilClass }
  let(:situation_expectations) { [] }

  # Candidate Specification
  let!(:candidate) do
    mandate = create(:mandate)
    company = create(:company, inquiry_blacklisted: true)
    category_ident = '47a1b441'
    category = create(:category, ident: category_ident)
    plan = create(:plan, company: company, category: category)

    create(:product,
                       mandate: mandate,
                       plan: plan,
                       contract_ended_at: 15.weeks.from_now + 1.day)
  end
  let(:candidates) do
    automatable = OpenStruct.new
    {
      automatable => true
    }
  end

  # Intent to be played
  let(:intent_class) { Platform::RuleEngineV3::Flows::MessageToQuestionnaire }
  # This options are nil because V3 intents do not have implemented the concept
  let(:intent_options) { {} }

  it_behaves_like 'v4 automation', [:not_compatible]
end
