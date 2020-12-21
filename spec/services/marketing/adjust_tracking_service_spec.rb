# frozen_string_literal: true

require "rails_helper"

describe Marketing::AdjustTrackingService do

  let(:mandate) { create(:mandate) }
  context "translate input params to request params" do
    activity_kind = "Incent Push"
    ios_name = "ios"
    android_name = "android"
    ios_appid = "1054790721"
    android_appid = "de.clark"
    advertiser_id = "sample-ad-id"
    let(:event_time) { Time.current.to_datetime }
    let(:clv) { (rand * 100).round }
    let(:params) do
      {
        activity_kind:     activity_kind,
        os_name:           ios_name,
        device_event_time: event_time,
        app_id:            ios_appid,
        advertiser_id:     advertiser_id,
        mandate_id:        mandate.id,
        revenue:           clv,
        currency:          "EUR"
      }
    end

    it "should set AdjustTrackingRemoteService as remote service on production" do
      allow(Rails).to receive(:env).and_return("production".inquiry)

      remote_service = Marketing::AdjustTrackingService.clone.instance.instance_variable_get("@remote_service")

      expect(remote_service).to be_a(Marketing::AdjustTrackingService::AdjustTrackingRemoteService)
    end

    it "should set AdjustTrackingRemoteService as remote service on staging" do
      allow(Rails).to receive(:env).and_return("staging-test-2".inquiry)

      remote_service = Marketing::AdjustTrackingService.clone.instance.instance_variable_get("@remote_service")

      expect(remote_service).to be_a(Marketing::AdjustTrackingService::AdjustTrackingRemoteService)
    end

    it "should set AdjustTrakcingFakeRemoteService as remote service on development" do
      allow(Rails).to receive(:env).and_return("development".inquiry)

      remote_service = Marketing::AdjustTrackingService.clone.instance.instance_variable_get("@remote_service")

      expect(remote_service).to eq(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService)
    end

    it "should set AdjustTrakcingFakeRemoteService as remote service on test" do
      remote_service = Marketing::AdjustTrackingService.clone.instance.instance_variable_get("@remote_service")

      expect(remote_service).to eq(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService)
    end

    it "should just pass through the activity kind and the os name" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(activity_kind: activity_kind, os_name: ios_name), mandate.id)
      Marketing::AdjustTrackingService.track(params)
    end

    it "should pass the device event time in a serialized way" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(created_at: event_time.strftime("%Y-%m-%dT%H:%M:%SZ%z")), mandate.id)
      Marketing::AdjustTrackingService.track(params)
    end

    it "should pass the ios app token, if the ios name and app id have been passed" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(app_token: Settings.adjust.app_token.ios[ios_appid]), mandate.id)
      Marketing::AdjustTrackingService.track(params)
    end

    it "should transfer the advertiser id fitting the ios plattform" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(idfa: advertiser_id), mandate.id)
      Marketing::AdjustTrackingService.track(params)
    end

    it "should transfer the advertiser id fitting the android plattform" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(gps_adid: advertiser_id), mandate.id)
      params[:os_name] = android_name
      params[:app_id] = android_appid
      Marketing::AdjustTrackingService.track(params)
    end

    it "should pass the ios app token, if the android name and app id have been passed" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(app_token: Settings.adjust.app_token.android[android_appid]), mandate.id)
      params[:os_name] = android_name
      params[:app_id] = android_appid
      Marketing::AdjustTrackingService.track(params)
    end

    it "should just on just adid if no advertiser_id is given and not throw any errors" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(adid: "adid"), mandate.id)
      params[:adid] = "adid"
      params[:advertiser_id] = nil
      Marketing::AdjustTrackingService.track(params)
    end

    it "should send the revenue" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(revenue: clv), mandate.id)
      Marketing::AdjustTrackingService.track(params)
    end

    it "should send the currency EUR" do
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(currency: "EUR"), mandate.id)
      Marketing::AdjustTrackingService.track(params)
    end

    Settings.adjust.event_token.each do |event_name, event_tokens|
      it "should pass the ios token '#{event_tokens[ios_name]}' for the event '#{event_name}' to the remote service" do
        expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(event_token: Settings.adjust.event_token[event_name].ios), mandate.id)
        Marketing::AdjustTrackingService.track(params.merge(activity_kind: event_name))
      end

      it "should pass the android token '#{event_tokens[android_name]}' for the event '#{event_name}' to the remote service" do
        expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(event_token: Settings.adjust.event_token[event_name].android), mandate.id)
        Marketing::AdjustTrackingService.track(params.merge(activity_kind: event_name, os_name: android_name, app_id: android_appid))
      end
    end

    it "should fail, if the os_name is not supported" do
      params[:os_name] = "not supported"
      expect {
        Marketing::AdjustTrackingService.track(params)
      }.to raise_error("Unsupported operating system: '#{params[:os_name]}'")
    end

    %i[activity_kind device_event_time app_id].each do |sym|
      it "should fail, if the parameter #{sym} is missing" do
        params.delete(sym)
        expect {
          Marketing::AdjustTrackingService.track(params)
        }.to raise_error("Parameter missing: :#{sym}")
      end
    end

    it "should make request even if os_name is missing" do
      params.delete(:os_name)
      expect(Marketing::AdjustTrackingService::AdjustTrackingFakeRemoteService).to receive(:send_event).with(hash_including(activity_kind: activity_kind), mandate.id)
      Marketing::AdjustTrackingService.track(params)
    end
  end

  # Will currently not make regression test remote calls out of tests, since this is a send and forget service without a remote test endpoint.

  context "remote service http error handling" do
    let(:fake_response) { double(message: "fake message", response_body_permitted?: true, body: "fake response", code: "200") }
    let(:remote_service) { Marketing::AdjustTrackingService::AdjustTrackingRemoteService.new }
    let(:event) { {key: "value"} }

    before do
      allow(Net::HTTP).to receive(:get_response) { fake_response }
    end

    it "should raise, if the request did not succeed for client reasons" do
      allow(fake_response).to receive(:code) { "400" }
      expect { remote_service.send_event(event, mandate.id) }.to raise_error(RuntimeError, /#{fake_response.code}/)
      expect { remote_service.send_event(event, mandate.id) }.to raise_error(RuntimeError, /#{fake_response.message}/)
      expect { remote_service.send_event(event, mandate.id) }.to raise_error(RuntimeError, /#{fake_response.body}/)
    end

    it "should raise, if the request did not succeed for server reasons" do
      allow(fake_response).to receive(:code) { "500" }
      expect { remote_service.send_event(event, mandate.id) }.to raise_error(RuntimeError, /#{fake_response.code}/)
      expect { remote_service.send_event(event, mandate.id) }.to raise_error(RuntimeError, /#{fake_response.message}/)
      expect { remote_service.send_event(event, mandate.id) }.to raise_error(RuntimeError, /#{fake_response.body}/)
    end

    it "should succeed, if the request returned a status code 200" do
      allow(fake_response).to receive(:code) { "200" }
      expect(URI).to receive(:encode).and_call_original
      expect {
        remote_service.send_event(event, mandate.id)
      }.not_to raise_error
    end
  end
end
