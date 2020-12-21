require 'rails_helper'

RSpec.describe Platform::RuleEngineV3::Rules::DemandcheckOldRule do
  let(:subject) { described_class }
  let(:questionnaire) { create(:questionnaire, identifier: 'bedarfscheck') }

  context '#initialize' do
    it 'expect a hash of options not nil' do
      expect {
        subject.new(nil)
      }.to raise_error(ArgumentError)
    end

    it 'expect a hash of options not a list' do
      expect {
        subject.new([])
      }.to raise_error(ArgumentError)
    end

    it 'expect options to contain mandate and admin' do
      expect {
        subject.new({product: double()})
      }.to raise_error(ArgumentError)
    end

    it 'expect options with mandate to contain admin' do
      expect {
        subject.new({mandate: double()})
      }.to raise_error(ArgumentError)
    end

    it 'expect to be valid with options containing admin and mandate' do
      expect {
        subject.new({mandate: double(), admin: double()})
      }.not_to raise_error
    end
  end

  context '#applicable' do
    let(:mandate) { create(:mandate)}
    let!(:questionnaire_answer) { create(:questionnaire_response, questionnaire: questionnaire, mandate: mandate, state: 'analyzed') }

    before(:each) do
      allow_any_instance_of(subject).to receive(:interacted_with_during_past_30_days).and_return(false)
    end


    it 'is not applicable if user answered demandcheck recently' do
      allow(mandate).to receive(:accepted?).and_return(true)

      expect(subject.new({mandate: mandate, admin: double()})).not_to be_applicable
    end

    it 'is applicable if user answered demandcheck more than one year ago' do
      allow(mandate).to receive(:accepted?).and_return(true)
      questionnaire_answer.update_attributes(created_at: 2.years.ago)

      expect(subject.new({mandate: mandate, admin: double()})).to be_applicable
    end

    it 'is not applicable on non accepted mandates' do
      allow(mandate).to receive(:accepted?).and_return(false)
      expect(subject.new({mandate: mandate, admin: double()})).not_to be_applicable
    end
  end

  context '#intent' do
    it 'returns an intent' do
      expect(subject.new({mandate: double(), admin: double()}).intent).to be_a(Platform::RuleEngineV3::Flows::MessageToQuestionnaire)
    end
  end
end
