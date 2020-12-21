require 'rails_helper'

describe Marketing::CustomerJourneyService::Loaders::BusinessEvent do
  let(:business_event) { FactoryBot.build :business_event,
                                           action: action,
                                           person: person,
                                           entity: entity,
                                           created_at: time }

  let(:time) { Time.zone.now }
  let(:loader) { Marketing::CustomerJourneyService::Loaders::BusinessEvent.new(nil) }
  before { allow(loader).to receive(:business_events).and_return([[business_event.action,
                                                                   business_event.entity_type,
                                                                   business_event.entity_id,
                                                                   business_event.person_type,
                                                                   business_event.created_at]]) } # mock database query

  subject { loader.load }

  describe 'creating mandates' do
    let(:action) { "start_creating" }
    let(:entity) { FactoryBot.build_stubbed :mandate }
    let(:person) { FactoryBot.build_stubbed :user }

    it 'returns a properly formatted event' do
      expect(subject.first.type).to eq("BusinessEvent")
      expect(subject.first.source).to eq("?")
      expect(subject.first.details).to eq("start_creating Mandate #{entity.id} (User)")
      expect(subject.first.happened_at).to eq(time)
    end
  end
end