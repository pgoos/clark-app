# frozen_string_literal: true

require "rails_helper"

RSpec.describe Middleware::DisableCookieForAhoyEvent, :integration, type: :request do
  context "with ahoy event" do
    it "returns the discards the session cookie when it's the only one" do
      json_get_v2 "/api/authenticity-token"
      session_cookie = response.headers["Set-Cookie"]

      post "/argos/events",
           params: {js: nil, visit_token: "visit_token", visitor_token: "visitor_token"},
           headers: {"HTTP_CACHE" => session_cookie}

      expect(response.headers["Set-Cookie"]).to be_nil
    end

    it "removes only the session cookie" do
      json_get_v2 "/api/authenticity-token"
      session_cookie = response.headers["Set-Cookie"]

      post "/argos/events", params: {js: true}, headers: {"HTTP_COOKIE" => session_cookie}

      expect(response.headers["Set-Cookie"]).to include "ahoy_visit"
      expect(response.headers["Set-Cookie"]).to include "ahoy_visitor"
      expect(response.headers["Set-Cookie"]).not_to include "_optisure_session"
    end

    it "temporarily removes only the session cookie on older /ahoy/events url as well" do
      json_get_v2 "/api/authenticity-token"
      session_cookie = response.headers["Set-Cookie"]

      post "/ahoy/events", params: {js: true}, headers: {"HTTP_COOKIE" => session_cookie}

      expect(response.headers["Set-Cookie"]).to include "ahoy_visit"
      expect(response.headers["Set-Cookie"]).to include "ahoy_visitor"
      expect(response.headers["Set-Cookie"]).not_to include "_optisure_session"
    end

    it "does not interfere with normal requests" do
      json_get_v2 "/api/authenticity-token"
      session_cookie = response.headers["Set-Cookie"]

      expect(session_cookie).to include "_optisure_session"
    end
  end
end
