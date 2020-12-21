# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeeplinkProcessController, :integration, type: :controller do
  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Filter
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Actions
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  describe "GET #handle" do
    context "on an iOS device" do
      before do
        request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7"
      end

      it "redirects to deeplink when app installed", skip: "No Deeplinks in iOS at the moment" do
        get :handle, params: {
          deep_link: "clarkapp%3A%2F%2Fde%2Flogin",
          has_app: "true",
          locale: "de",
          fallback: "/de%2Fregister",
          adjust_android_tracker: "12345",
          adjust_ios_tracker: "54321",
          campaign: "mandate_reminder",
          network: "Email"
        }

        expect(response).to redirect_to("clarkapp://de/login")
      end

      it "redirects to fallback when app not installed" do
        get :handle, params: {
          deep_link: "clarkapp%3A%2F%2Fde%2Flogin",
          has_app: "false",
          locale: "de",
          fallback: "/de%2Fregister",
          adjust_android_tracker: "12345",
          adjust_ios_tracker: "54321",
          campaign: "mandate_reminder",
          network: "Email"
        }

        expect(response).to redirect_to("/de/register")
      end

      it "only considers the path on the fallback param" do
        get :handle, params: {
          deep_link: "clarkapp%3A%2F%2Fde%2Flogin",
          has_app: "false",
          locale: "de",
          fallback: "http://malicious-website.com/de%2Fregister",
          adjust_android_tracker: "12345",
          adjust_ios_tracker: "54321",
          campaign: "mandate_reminder",
          network: "Email"
        }

        expect(response).to redirect_to("/de/register")
      end
    end

    context "on an Android device" do
      before do
        request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Linux; U; Android 6.0.1; en-us; Nexus 5 Build/FRG83) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
      end

      it "redirects to adjust when app installed" do
        get :handle, params: {
          deep_link: "clarkapp%3A%2F%2Fde%2Flogin",
          has_app: "true",
          locale: "de",
          fallback: "/de%2Fregister",
          adjust_android_tracker: "12345",
          adjust_ios_tracker: "54321",
          campaign: "mandate_reminder",
          network: "Email"
        }

        expect(response).to redirect_to("https://app.adjust.com/12345_54321?campaign=mandate_reminder&deep_link=clarkapp%3A%2F%2Fde%2Flogin&fallback=/de%2Fregister&network=Email")
      end

      it "redirects to adjust even when app not installed" do
        get :handle, params: {
          deep_link: "clarkapp%3A%2F%2Fde%2Flogin",
          has_app: "false",
          locale: "de",
          fallback: "/de%2Fregister",
          adjust_android_tracker: "12345",
          adjust_ios_tracker: "54321",
          campaign: "mandate_reminder",
          network: "Email"
        }

        expect(response).to redirect_to("https://app.adjust.com/12345_54321?campaign=mandate_reminder&deep_link=clarkapp%3A%2F%2Fde%2Flogin&fallback=/de%2Fregister&network=Email")
      end
    end

    context "on Desktop" do
      it "redirects to fallback" do
        get :handle, params: {
          deep_link: "clarkapp%3A%2F%2Fde%2Flogin",
          has_app: "true",
          locale: "de",
          fallback: "/de%2Fregister",
          adjust_android_tracker: "12345",
          adjust_ios_tracker: "54321",
          campaign: "mandate_reminder",
          network: "Email"
        }

        expect(response).to redirect_to("/de/register")
      end
    end

    it "redirects to homepage if parameters are missing" do
      get :handle, params: {deep_link: "de%2Flogin", has_app: "true", locale: "de"}

      expect(response).to redirect_to(root_path)
    end
  end
end
