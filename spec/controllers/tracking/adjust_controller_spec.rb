# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tracking::AdjustController, :integration, type: :controller do
  describe "ip whitelisting" do
    it "should return a 403 (not authorized), if coming from an unknown ip" do
      request.headers["REMOTE_ADDR"] = "104.155.73.225"
      get :event, params: {locale: "de", activity_kind: "click", event_time: Time.new.to_i}
      expect(response.status).to eq(403)
    end

    it "should work for the localhost" do
      request.headers["REMOTE_ADDR"] = "127.0.0.1"
      get :event, params: {locale: "de", activity_kind: "click", event_time: Time.new.to_i}
      expect(response.status).to eq(204)
    end

    it "should work for the IPv6 range" do
      request.headers["REMOTE_ADDR"] = "2a0b:14c0:0000:0000:0000:0000:0000:0000"
      get :event, params: {locale: "de", activity_kind: "click", event_time: Time.new.to_i}
      expect(response.status).to eq(204)
    end

    it_behaves_like "adjacent networks", %w[2a0b:14c0::/32]
    it_behaves_like "adjacent networks", %w[23.19.48.0/22]
    it_behaves_like "adjacent networks", %w[173.208.60.0/23]
    it_behaves_like "adjacent networks", %w[178.162.200.128/26]
    it_behaves_like "adjacent networks", %w[178.162.216.64/26 178.162.216.128/26 178.162.216.192/26]
    it_behaves_like "adjacent networks", %w[178.162.219.0/24]
    it_behaves_like "adjacent networks", %w[185.151.204.0/22]
  end

  # Actions
  # ---------------------------------------------------------------------------------------

  describe "GET #event" do
    before do
      allow(Domain::Tracking::RegulateAdjustEvents)
        .to receive(:fill_mandate_in_previous_to!)
      request.headers["REMOTE_ADDR"] = "127.0.0.1"
    end

    it "returns a http client error, if no parameters given" do
      get_event
      expect(response.status).to eq(400)
      expect(response.content_type).to eq "application/json"
      errors = [
        "URL is missing parameters!",
        "missing param: activity_kind",
        "missing param: event_time"
      ]
      expect(json_response["errors"]).to match_array errors
    end

    context "publisher_parameters is a string" do
      let(:mandate) { create(:mandate) }

      it "should extract the mandate id" do
        expected_activity_kind = "click"
        expected_event_time    = Time.new.to_i

        get_event(
          activity_kind:        expected_activity_kind,
          event_time:           expected_event_time,
          publisher_parameters: {mandate_id: mandate.id}.to_json
        )

        event = Tracking::AdjustEvent.last

        expect(response.status).to eq(204)
        expect(event.mandate).to eq mandate
      end
    end

    context "when the param activity_kind and the event_time is given" do
      let(:mandate) { create :mandate }

      it "returns a success without content" do
        expected_activity_kind = "click"
        expected_event_time    = Time.new.to_i

        get_event(
          activity_kind:        expected_activity_kind,
          event_time:           expected_event_time,
          publisher_parameters: {mandate_id: mandate.id}
        )
        expect(response.status).to eq(204)
        event = Tracking::AdjustEvent.last
        expect(event.activity_kind).to eq(expected_activity_kind)
        expect(event.event_time).to eq(Time.zone.at(expected_event_time).to_datetime)
        expect(event.params).not_to be(nil)
        expect(event.mandate).to eq mandate
      end

      it "sets mandate for events previous to current" do
        get_event(
          activity_kind: "click",
          event_time:    Time.zone.now.to_i,
          mandate_id:    mandate.id
        )
        event = Tracking::AdjustEvent.last
        expect(Domain::Tracking::RegulateAdjustEvents)
          .to have_received(:fill_mandate_in_previous_to!).with(event)
      end
    end

    context "forwardable tracking" do
      it "forwards ios install events from the campaign 'Incent_Push' to adjust" \
         " as 'Incent Push' event" do
        event_time = Time.current
        expect(Marketing::AdjustTrackingService.instance).to receive(:track).with(
          hash_including(
            activity_kind:     "Incent Push",
            os_name:           "ios",
            app_id:            "1054790721",
            device_event_time: event_time.to_datetime,
            advertiser_id:     "advertiser_id_value_ios"
          )
        )
        get_event(
          activity_kind: "install",
          event_time:    event_time.to_i,
          campaign_name: "Incent_Push",
          app_id:        "1054790721",
          idfa:          "advertiser_id_value_ios"
        )
        expect(response.status).to eq(204)
      end

      it "forwards android install events from the campaign 'Incent_Push' to adjust" \
         " as 'Incent Push' event" do
        event_time = Time.current
        expect(Marketing::AdjustTrackingService.instance).to receive(:track).with(
          hash_including(
            activity_kind:     "Incent Push",
            os_name:           "android",
            app_id:            "de.clark",
            device_event_time: event_time.to_datetime,
            advertiser_id:     "advertiser_id_value_android"
          )
        )
        get_event(
          activity_kind: "install",
          event_time:    event_time.to_i,
          campaign_name: "Incent_Push",
          app_id:        "de.clark",
          gps_adid:      "advertiser_id_value_android"
        )
        expect(response.status).to eq(204)
      end

      it "should not forward the event, if it is not an install event" do
        expect(Marketing::AdjustTrackingService.instance).not_to receive(:track)
        get_event(
          activity_kind: "other",
          event_time:    Time.current.to_i,
          campaign_name: "Incent_Push"
        )
        expect(response.status).to eq(204)
      end

      it "should not forward the event, if it is not from the Incent_Push campaign" do
        expect(Marketing::AdjustTrackingService.instance).not_to receive(:track)
        get_event(
          activity_kind: "install",
          event_time:    Time.current.to_i,
          campaign_name: "other campaign"
        )
        expect(response.status).to eq(204)
      end
    end

    context "when the environment parameter is not production" do
      it "accepts but not store events on production" do
        allow(Rails).to receive_message_chain("env.production?").and_return(true)
        allow(Rails).to receive_message_chain("env.development?").and_return(false)
        expect {
          get_event(
            activity_kind: "click",
            event_time:    Time.current.to_i,
            environment:   "sandbox"
          )
        }.not_to(change { Tracking::AdjustEvent.count })
        expect(response.status).to eq(202)
      end
    end

    context "the environment parameter is production" do
      it "accepts but not store events on environments unequal to production" do
        allow(Rails).to receive_message_chain("env.production?").and_return(false)
        allow(Rails).to receive_message_chain("env.development?").and_return(true)
        expect {
          get_event(
            activity_kind: "click",
            event_time:    Time.current.to_i,
            environment:   "production"
          )
        }.not_to(change { Tracking::AdjustEvent.count })
        expect(response.status).to eq(202)
      end
    end

    def get_event(params={})
      get_params = {locale: "de"}
      get :event, params: get_params.merge(params)
    end
  end
end
