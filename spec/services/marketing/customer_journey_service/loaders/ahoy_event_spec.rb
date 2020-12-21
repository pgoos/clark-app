require 'rails_helper'

describe Marketing::CustomerJourneyService::Loaders::AhoyEvent do
  let(:ahoy_event) { FactoryBot.build :tracking_event,
                                       name: name,
                                       properties: properties,
                                       time: time }

  let(:time) { Time.zone.now }
  let(:loader) { Marketing::CustomerJourneyService::Loaders::AhoyEvent.new(nil) }
  before { allow(loader).to receive(:ahoy_events).and_return([[ahoy_event.name, ahoy_event.properties, ahoy_event.time]]) } # mock database query

  subject { loader.load }

  describe 'page views' do
    let(:properties) { { pathname: 'and/its/path', pageTitle: 'The Page Title' } }
    let(:name) { 'pageview' }

    it 'returns a properly formatted event' do
      expect(subject.first.type).to eq("Page view")
      expect(subject.first.source).to eq("Web")
      expect(subject.first.details).to eq("The Page Title (and/its/path)")
      expect(subject.first.happened_at).to eq(time)
    end
  end

  describe 'cockpit views' do
    let(:properties) { { pathname: 'and/its/path', pageTitle: 'The Page Title' } }
    let(:name) { 'cockpit_view' }

    it 'returns a properly formatted event' do
      expect(subject.first.type).to eq("Cockpit view")
      expect(subject.first.source).to eq("Web")
      expect(subject.first.details).to eq("The Page Title (and/its/path)")
      expect(subject.first.happened_at).to eq(time)
    end
  end

  describe 'app installs' do
    let(:properties) { { screen_name: 'Splash', category: 'Registration', installation_id: 'some id' } }
    let(:name) { 'app_install' }

    it 'returns a properly formatted event' do
      expect(subject.first.type).to eq("App install")
      expect(subject.first.source).to eq("Mobile")
      expect(subject.first.details).to eq("Screen: Splash - Category: Registration")
      expect(subject.first.happened_at).to eq(time)
    end
  end

  describe 'app starts' do
    let(:properties) { { campaign: 'leverate-CPI', category: 'Registration', installation_id: 'some id' } }
    let(:name) { 'app_start' }

    it 'returns a properly formatted event' do
      expect(subject.first.type).to eq("App start")
      expect(subject.first.source).to eq("Mobile")
      expect(subject.first.details).to eq("Campaign: leverate-CPI - Category: Registration")
      expect(subject.first.happened_at).to eq(time)
    end
  end
end