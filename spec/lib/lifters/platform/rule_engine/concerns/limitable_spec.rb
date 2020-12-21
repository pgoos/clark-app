require 'rails_helper'

RSpec.describe Platform::RuleEngineV3::Concerns::Limitable do
  FakeInteraction = Struct.new(:created_at)

  let(:subject) do
    class LimitedClass
      include Platform::RuleEngineV3::Concerns::Limitable
    end
    LimitedClass.new
  end

  context '#interacted_with_during_past_30_days' do
    let(:mandate) { create(:mandate) }
    let(:admin) { create(:admin) }
    let(:interaction_list) { [] }

    it 'with mandate with nil interactions' do
      allow(mandate).to receive(:interactions).and_return(nil)

      expect(subject.interacted_with_during_past_30_days(mandate)).to eq(false)
    end

    it 'with mandate with 0 interactions' do
      allow(mandate).to receive(:interactions).and_return([])

      expect(subject.interacted_with_during_past_30_days(mandate)).to eq(false)
    end

    it 'with mandate with 1 interaction that is old' do
      create(:interaction_advice, created_at: 45.days.ago, mandate: mandate, admin: admin, topic: mandate)
      expect(subject.interacted_with_during_past_30_days(mandate)).to eq(false)
    end

    it 'with mandate with 1 interaction that is recent' do
      create(:interaction_advice, created_at: 5.days.ago, mandate: mandate, admin: admin, topic: mandate)
      expect(subject.interacted_with_during_past_30_days(mandate)).to eq(true)
    end
  end
end
