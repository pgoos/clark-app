require 'rails_helper'

describe Marketing::CustomerJourneyService::Events do

  describe 'stream' do
    subject { Marketing::CustomerJourneyService::Events.new(mandate, start_date, end_date).stream }

    let!(:mandate) { create :mandate }
    let(:start_date) { Time.zone.now - 3.days }
    let(:end_date) { Time.zone.now - 1.days }

    let(:before_date) { start_date - 1.days }
    let(:within_date) { Time.zone.now - 2.days }
    let(:after_date) { end_date + 1.days }

    context 'when ahoy visits exist' do
      let!(:tracking_visit_before) { create :tracking_visit, mandate: mandate, started_at: before_date }
      let!(:tracking_visit_within) { create :tracking_visit, mandate: mandate, started_at: within_date, browser: "Mosaic", os: "Windows", landing_page: "http://clark-ist-cool.de", device_type: "Desktop" }
      let!(:tracking_visit_after) { create :tracking_visit, mandate: mandate, started_at: after_date }
      let!(:tracking_visit_other_mandate) { create :tracking_visit, mandate: create(:mandate), started_at: within_date }

      it 'includes only tracking visits within between start and end date and for given mandate'  do
        expect(subject.size).to be 1
        expect(subject.first.type).to eq("Visit")
        expect(subject.first.source).to eq("Web")
        expect(subject.first.details).to eq("Mosaic (Windows): http://clark-ist-cool.de")
        expect(subject.first.happened_at.strftime("%Y.%m.%d %H:%M:%S")).to eq(tracking_visit_within.started_at.strftime("%Y.%m.%d %H:%M:%S"))
      end
    end

    context 'when ahoy events exist' do
      let!(:tracking_event_before) { create :tracking_event, mandate: mandate, time: before_date, properties: properties, name: name }
      let!(:tracking_event_within) { create :tracking_event, mandate: mandate, time: within_date, properties: properties, name: name }
      let!(:tracking_event_after) { create :tracking_event, mandate: mandate, time: after_date, properties: properties, name: name }
      let!(:tracking_event_other_mandate) { create :tracking_event, mandate: create(:mandate), time: within_date, properties: properties, name: name }
      let!(:tracking_event_other_type) { create :tracking_event, mandate: create(:mandate), time: within_date, properties: properties, name: 'some_excluded_type' }

      context 'when event is pageview' do
        let(:properties) { { pathname: 'and/its/path', pageTitle: 'The Page Title' } }
        let(:name) { 'pageview' }

        it 'includes only page view events within between start and end date and for given mandate'  do
          expect(subject.size).to be 1
          expect(subject.first.type).to eq("Page view")
          expect(subject.first.source).to eq("Web")
          expect(subject.first.details).to eq("The Page Title (and/its/path)")
          expect(subject.first.happened_at.strftime("%Y.%m.%d %H:%M:%S")).to eq(tracking_event_within.time.strftime("%Y.%m.%d %H:%M:%S"))
        end
      end
    end

    context 'when adjust events exist' do
      let!(:adjust_event_before) { create :tracking_adjust_event, mandate: mandate, created_at: before_date, activity_kind: "install" }
      let!(:adjust_event_within) { create :tracking_adjust_event, mandate: mandate, created_at: within_date, activity_kind: "install", params: { os_name: 'android', campaign_name: 'some_campaign' } }
      let!(:adjust_event_after) { create :tracking_adjust_event, mandate: mandate, created_at: after_date, activity_kind: "install" }
      let!(:adjust_event_other_mandate) { create :tracking_adjust_event, mandate: create(:mandate), created_at: within_date, activity_kind: "install" }
      let!(:adjust_event_excluded_activity_kind) { create :tracking_adjust_event, mandate: create(:mandate), created_at: within_date, activity_kind: "event" }

      it 'includes only adjust events within between start and end date and for given mandate'  do
        expect(subject.size).to be 1
        expect(subject.first.type).to eq("App install")
        expect(subject.first.source).to eq("Mobile")
        expect(subject.first.details).to eq("OS: android - Campaign: some_campaign")
        expect(subject.first.happened_at.strftime("%Y.%m.%d %H:%M:%S")).to eq(adjust_event_within.created_at.strftime("%Y.%m.%d %H:%M:%S"))
      end
    end

    context 'when business events exist' do
      let!(:business_event_before) { create :business_event, audited_mandate: mandate, created_at: before_date, action: "send_greeting_email" }
      let!(:business_event_within) { create :business_event, audited_mandate: mandate, created_at: within_date, action: "send_greeting_email", entity: create(:mandate), person: create(:user) }
      let!(:business_event_after) { create :business_event, audited_mandate: mandate, created_at: after_date, action: "send_greeting_email" }
      let!(:business_event_other_mandate) { create :business_event, audited_mandate: create(:mandate), created_at: within_date, action: "send_greeting_email" }
      let!(:business_event_excluded_action_1) { create :business_event, audited_mandate: create(:mandate), created_at: within_date, action: "create" }
      let!(:business_event_excluded_action_2) { create :business_event, audited_mandate: create(:mandate), created_at: within_date, action: "update" }
      let!(:business_event_excluded_action_3) { create :business_event, audited_mandate: create(:mandate), created_at: within_date, action: "delete" }

      it 'includes only business events within between start and end date, for given mandate, and without excluded actions'  do
        expect(subject.size).to be 1
        expect(subject.first.type).to eq("BusinessEvent")
        expect(subject.first.source).to eq("?")
        expect(subject.first.details).to eq("send_greeting_email Mandate #{business_event_within.entity.id} (User)")
        expect(subject.first.happened_at.strftime("%Y.%m.%d %H:%M:%S")).to eq(business_event_within.created_at.strftime("%Y.%m.%d %H:%M:%S"))
      end
    end

    context 'when interactions exist' do
      let!(:interaction_before) { create :interaction, mandate: mandate, created_at: before_date }
      let!(:interaction_within) { create :interaction, mandate: mandate, created_at: within_date, type: 'Interaction::Email', topic: create(:opportunity), direction: 'out', content: 'some_content' }
      let!(:interaction_after) { create :interaction, mandate: mandate, created_at: after_date }
      let!(:interaction_other_mandate) { create :interaction, mandate: create(:mandate), created_at: within_date }

      it 'includes only interactions within between start and end date and for given mandate'  do
        expect(subject.size).to be 1
        expect(subject.first.type).to eq("Email out (Opportunity)")
        expect(subject.first.source).to eq("?")
        expect(subject.first.details).to eq(interaction_within.content)
        expect(subject.first.happened_at.strftime("%Y.%m.%d %H:%M:%S")).to eq(interaction_within.created_at.strftime("%Y.%m.%d %H:%M:%S"))
      end
    end

    context 'when feed logs exist' do
      let!(:feed_log_before) { create :feed_log, mandate: mandate, created_at: before_date, event: "feed-opened" }
      let!(:feed_log_within) { create :feed_log, mandate: mandate, created_at: within_date, text: "Feed was opened", event: "feed-opened" }
      let!(:feed_log_after) { create :feed_log, mandate: mandate, created_at: after_date, event: "feed-opened" }
      let!(:feed_log_other_mandate) { create :feed_log, mandate: create(:mandate), created_at: within_date, event: "feed-opened" }
      let!(:feed_log_non_included_event) { create :feed_log, mandate: create(:mandate), created_at: within_date, event: "non_included_event" }

      it 'includes only interactions within between start and end date and for given mandate'  do
        expect(subject.size).to be 1
        expect(subject.first.type).to eq('Feed')
        expect(subject.first.source).to eq("?")
        expect(subject.first.details).to eq("Feed was opened")
        expect(subject.first.happened_at.strftime("%Y.%m.%d %H:%M:%S")).to eq(feed_log_within.created_at.strftime("%Y.%m.%d %H:%M:%S"))
      end
    end
  end
end