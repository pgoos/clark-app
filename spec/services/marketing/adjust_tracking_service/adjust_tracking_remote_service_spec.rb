# frozen_string_literal: true

require "rails_helper"

describe Marketing::AdjustTrackingService::AdjustTrackingRemoteService do
  let(:advertiser_id) { "sample-ad-id"     }
  let(:app_token)     { "sample-app-token" }

  let(:event) do
    {
      activity_kind:     "mandate_accepted",
      os_name:           "ios",
      device_event_time: Time.current.to_datetime,
      app_id:            "1054790721",
      idfa:              advertiser_id,
      mandate_id:        20,
      revenue:           "20",
      currency:          "EUR",
      app_token:         app_token
    }
  end

  context "when adjust returns error" do
    before do
      stub_request(:get, /adjust.com/).to_return(status: 500, body: "SAMPLE BODY", headers: {})
    end

    it "sanitizes sensitive params in exception message" do
      exception_message =
        begin
          described_class.new.send_event(event, event[:manend_eventate_id])
        rescue RuntimeError => e
          e.message
        end

      expect(exception_message).to include("app_id")
      expect(exception_message).to include("activity_kind")

      expect(exception_message).to include(event[:app_id])
      expect(exception_message).to include(event[:activity_kind])

      expect(exception_message).not_to include(advertiser_id)
      expect(exception_message).not_to include(app_token)
    end
  end
end
