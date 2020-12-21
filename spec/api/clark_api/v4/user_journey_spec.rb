# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::UserJourney, :integration, :business_events do
  let(:admin) { create(:admin, role: create(:role)) }

  context "when putting a new event" do
    let(:params) { {event: "rating_modal_triggered", payload: {cause: "some_cause"}} }

    it "should return a 401, if not authenticated" do
      expect {
        json_put_v4 "/api/journey/event", params
      }.to change(BusinessEvent, :count).by(0)
      expect(response.status).to eq(401)

      json_get_v4 "/api/journey/rating"
      expect(response.status).to eq(401)
    end

    context "when logged in" do
      let(:user) { create(:user, :with_mandate) }

      before do
        login_as(user, scope: :user)
      end

      it "should put new events" do
        # try to put an event:
        json_put_v4 "/api/journey/event", params
        expect(response.status).to eq(200)

        reminder_cycle_times = json_response.reminder_cycle_times
        expect(reminder_cycle_times).to be_a(Hash)
        expect(reminder_cycle_times[:positive1view]).to be_an(Integer)

        journey = Domain::Users::JourneyEvents.new(mandate: user.mandate)
        event = journey.events.last
        expect(event.action).to eq(params[:event])
        expect(json_response.triggered).to eq(true)

        # put a second event and verify the effect
        json_put_v4 "/api/journey/event", event: "rating_modal_shown"
        expect(response.status).to eq(200)
        expect(json_response.triggered).to eq(false)

        # query the rating status and verify the contract
        json_get_v4 "/api/journey/rating"
        expect(response.status).to eq(200)

        reminder_cycle_times = json_response.reminder_cycle_times
        user.reload
        rating_status = Domain::Users::JourneyEvents.new(mandate: user.mandate).rating_status

        expect(reminder_cycle_times).to eq(rating_status.reminder_cycle_times.to_h.stringify_keys)
        expect(json_response.last_shown).to eq(rating_status.last_shown.as_json)
        expect(json_response.rated).to be(rating_status.rated?)
        expect(json_response.last_rating_positive).to eq(rating_status.last_rating&.positive)
        expect(json_response.dismissed).to be(rating_status.dismissed?)
        expect(json_response.triggered).to be(rating_status.triggered?)
        expect(json_response.positive_ratings_count).to eq(rating_status.positive_ratings_count)
        expect(json_response).to have_key("native_modal_enabled")
      end
    end
  end
end
