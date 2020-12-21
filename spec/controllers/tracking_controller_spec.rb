# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a localized tracking controller" do |args|
  provide_locale = args[:locale]
  context_text = provide_locale ? "with locale" : "without locale"

  context context_text do
    let(:opt_out_tracking_cookie) { TrackingController::OPT_OUT_TRACKING_COOKIE }
    let(:locale) { I18n.locale }
    let(:locale_params) do
      provide_locale ? {locale: I18n.locale} : {}
    end

    describe "GET /tracking/opt-out" do
      it "should redirect root path" do
        get "/tracking/opt-out", params: locale_params

        expect(response).to redirect_to(root_path(locale: locale))
      end

      it "should set an opt-out cookie" do
        get "/tracking/opt-out", params: locale_params

        expect(response.cookies[opt_out_tracking_cookie]).to eq("true")
      end
    end

    describe "GET /tracking/opt-in" do
      before do
        cookies[opt_out_tracking_cookie] = "true"
      end

      it "should redirect root path" do
        get "/tracking/opt-in", params: locale_params

        expect(response).to redirect_to(root_path(locale: locale))
      end

      it "should remove the cookie" do
        get "/tracking/opt-in", params: locale_params

        expect(response.cookies[opt_out_tracking_cookie]).to be_nil
      end
    end

    describe "GET /tracking-page.html" do
      it "should have response success" do
        get "/de/tracking-page.html", params: locale_params

        expect(response).to be_successful
      end
    end
  end
end

RSpec.describe TrackingController, :integration, type: :request do
  it_behaves_like "a localized tracking controller", locale: true
  it_behaves_like "a localized tracking controller", locale: false
end
