require 'rails_helper'

describe Marketing::CustomerJourneyService::Loaders::AdjustEvent do
  let(:adjust_event) { FactoryBot.build :tracking_adjust_event,
                                         activity_kind: activity_kind,
                                         params: params,
                                         created_at: time }

  let(:time) { Time.zone.now }
  let(:loader) { Marketing::CustomerJourneyService::Loaders::AdjustEvent.new(nil) }
  before { allow(loader).to receive(:adjust_events).and_return([[adjust_event.activity_kind, adjust_event.params, adjust_event.created_at]]) } # mock database query

  subject { loader.load }

  describe 'app installs' do
    let(:activity_kind) { "install" }
    let(:params) { { os_name: 'android', campaign_name: 'leverate-CPI' } }

    it 'returns a properly formatted event' do
      expect(subject.first.type).to eq("App install")
      expect(subject.first.source).to eq("Mobile")
      expect(subject.first.details).to eq("OS: android - Campaign: leverate-CPI")
      expect(subject.first.happened_at).to eq(time)
    end
  end

  describe 'app sessions' do
    let(:activity_kind) { "session" }
    let(:params) { { os_name: 'android' } }

    it 'returns a properly formatted event' do
      expect(subject.first.type).to eq("App session")
      expect(subject.first.source).to eq("Mobile")
      expect(subject.first.details).to eq("OS: android")
      expect(subject.first.happened_at).to eq(time)
    end
  end
end